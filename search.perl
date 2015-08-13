#!/usr/bin/perl

use Scalar::Util 'blessed';
use List::Util qw(min max);
use Net::Twitter;
use Data::Dumper;
use Time::localtime;
use Time::Piece;
use Encode;
use utf8;
binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';
use IO::Handle;

$consumer_key1    = 'KnzpHso9d7qXfXT72Y0sly360';
$consumer_secret1 = 'mQbryk7RInrRp3QZuSkqH4U59H4NsWQj4X8pWFspajklbirCFS';
$token1           = '3288314879-pysLtV3l1CnMo3hvRWaGf1KggPQP2xr4SqqcsFy';
$token_secret1    = 'jSGfcnlJAGxZLfbx7CbjGFSDPHP4i7u0NA0UqsU8f60qO';

$consumer_key2    = 'zLQRN4RKE3xBJCDpErbgWWVUO';
$consumer_secret2 = 'M9ezYeQEm5WP84kXycbNA7Zo74lG8DS4gj86THKOzacT1yTBqC';
$token2           = '3288314879-dgIk2nZV9yULyllrG9KeFkonoJNdrNZBbkh62VC';
$token_secret2    = 'HYiIJYnxvPoaZsW9awDKOSKiNcuE2ofyMteSEQwCbVmBQ';

$sleep   = 90;
$max_returned_ok_0status = 10; ### connection ok but 0 status returned
$max_returned_ko = 10; ### connection ko

$_lang        = "";
$_until       = "";
$_result_type = "recent";
$_count       = 100;
$_max_id      = 0;
$_min_epoch   = 0;
$_app         = "crawl1";

$usage="$0 -q \"STRING\" -a {crawl1,crawl2} -l LANG -o FILE [-m DATE] [-M INT] [-c INT] [-t TYPE]
   -q STRING : list of terms (Ex: \"earthquake OR extreme heat\")
   -a STRING : crawl1 crawl2
   -l LANG   : language (default: not used)
   -o FILE   : output file (FILE.{DATE,DATE.log} files)
 Options:
   -m INT    : return tweets generated after (more recents than) DATE 'YYYY-MM-DDTHH:MM:SS' (default: not used)
   -M INT    : return tweets with id lower (older) than INT (default: not used)
   -c INT    : number of returned tweets [1,100] (default: $_count)
   -t TYPE   : result type {recent,popular,mixed} (default: $_result_type)
";

%tweet_ids=();
while ($#ARGV>=0){
    $tok = shift @ARGV;
#    if ($tok eq "-q" && $#ARGV>=0) {$_query=&escape(decode("utf-8",shift @ARGV)); next;} 
    if ($tok eq "-q" && $#ARGV>=0) {$_query=decode("utf-8",shift @ARGV); next;} 
    if ($tok eq "-a" && $#ARGV>=0) {$_app=shift @ARGV; next;} 
    if ($tok eq "-l" && $#ARGV>=0) {$_lang=shift @ARGV; next;} 
    if ($tok eq "-m" && $#ARGV>=0) {$_min_epoch=shift @ARGV; next;} 
    if ($tok eq "-M" && $#ARGV>=0) {$_max_id=shift @ARGV; next;} 
    if ($tok eq "-c" && $#ARGV>=0) {$_count=shift @ARGV; next;} 
    if ($tok eq "-t" && $#ARGV>=0) {$_result_type=shift @ARGV; next;} 
    if ($tok eq "-o" && $#ARGV>=0) {$_fout=shift @ARGV; next;} 
    die "error: unparsed '$tok' option\n$usage";
}
die "\nerror: missing -o option\n$usage" unless (defined $_fout);
die "\nerror: missing -q option\n$usage" unless (defined $_query);
die "\nerror: missing -a option\n$usage" unless (defined $_app);
die "\nerror: missing -l option\n$usage" unless (defined $_lang);

my ($consumer_key,$consumer_secret,$token,$token_secret);
if ($_app eq "crawl1"){
    $consumer_key = $consumer_key2;
    $consumer_secret = $consumer_secret2;
    $token = $token2;
    $token_secret = $token_secret2;
}
elsif ($_app eq "crawl2"){
    $consumer_key = $consumer_key2;
    $consumer_secret = $consumer_secret2;
    $token = $token2;
    $token_secret = $token_secret2;
}
else {die "unparsed -a option\n$usage";}

$now=ctime();#Wed May 13 09:36:24 2015
#$time = (localtime Time::Piece->strptime($now, "%a %b %d %T %Y"))->epoch;#1431502584
$now = (localtime Time::Piece->strptime($now, "%a %b %d %T %Y"))->datetime;#2015-05-13T09:52:59
$now =~ s/[\-\:]/\_/g;
$now =~ s/T/\-/;#2015_05_13-09_52_59
$_fout .= "___".$now."___".$_query."___".$_app."___".$_result_type;
$_fout =~ s/ /\_/g;
open (FOUT,">$_fout") or die "error: cannot open fout: $_fout\n";
open (FERR,">$_fout.log") or die "error: cannot open ferr: $_fout.log\n";
print STDERR "dumping results in file: $_fout\n";

$_min_epoch = &epoch_of($_min_epoch) if ($_min_epoch);

$nt = Net::Twitter->new(
    traits              => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
    ssl                 => 1
    );

$n_tweets=0;
$n_iter=0;
$alldatesmin=0;
$returned0statuses=0;
$returnedko=0;
while (++$n_iter){ ### forever
    #####################
    ### build query
    #####################
    %query=();
    $query{"q"}=$_query;
    $query{"lang"}=$_lang                unless ($_lang eq "");
    $query{"result_type"}=$_result_type  unless ($_result_type eq "");
    $query{"count"}=$_count              unless ($_count eq "");
    $query{"max_id"}=$_max_id            unless ($_max_id == 0);
    $dumped=Dumper(\%query);
    $dumped=~s/[\n\s]+/ /g;
    print FERR "Iter=$n_iter app=$_app Query: $dumped\n";
    FERR->flush();
    #####################
    ### run search
    #####################
    my $r;
    eval {
	local $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(10); ### activate alarm
	eval { $r = $nt->search(\%query) };
	alarm(0); ### deactivate alarm
    };
    #####################
    ### error handling
    #####################
    if ( my $err = $@ ){
	if ($err eq "alarm\n"){
	    print FERR "[KO] ALARM received... sleeping $sleep! (Iter=$n_iter max_id=$_max_id)\n";
	    FERR->flush();
	    sleep $sleep;
	    next;
	}
	die "error: $@" unless (blessed $err && $err->isa('Net::Twitter::Error'));
	die "HTTP Response Code: ".$err->code."\nHTTP Message......: ".$err->message."\nTwitter error.....: ".$err->error."\n";
	FERR->flush();
    }
    if ($r->{statuses}){
	if (scalar @{$r->{statuses}} == 0) {$returned0statuses++;}
	else {$returned0statuses=0;}
	$returnedko=0;
	print FERR "[OK] received ".(scalar @{$r->{statuses}})." statuses (Iter=$n_iter) max_id=$_max_id returned0statuses=$returned0statuses\n";
	FERR->flush();
	last if ($returned0statuses >= $max_returned_ok_0status);
    }
    else{
	$returned0statuses=0;
	$returnedko++;
	print FERR "[KO] no results received... sleeping $sleep! (Iter=$n_iter) max_id=$_max_id returnedKOs=$returnedko\n";
	FERR->flush();
	last if ($returnedko >= $max_returned_ko);
	sleep $sleep;
	next;
    }
    #####################
    ### handle results
    #####################
    my ($currid,$currepoch,$currdate);    
    $alldatesmin=1;
    foreach $entry (@{$r->{statuses}}) {
	$currid=$entry->{id};
	$currdate=$entry->{created_at};
	$currepoch=&epoch_of($currdate);
	$_max_id=$currid-1 if (!$_max_id || $currid<$_max_id);
	$alldatesmin=0 if ($_min_epoch && &epoch_of($currdate) > $_min_epoch);
	$n_tweets++;
	print FOUT Dumper($entry);
	FOUT->flush();
    }
    last if ($_min_epoch && $alldatesmin);
    FERR->flush();
}
print FERR "End ntweets=$n_tweets (reached min_date)\n" if ($_min_epoch && $alldatesmin);
print FERR "End ntweets=$n_tweets\n";
close FOUT;
close FERR;

exit;

sub epoch_of{
    ############# input format is:
    # datetime  : 2015-05-12T13:28:05
    # created_at: Tue May 12 12:41:40 +0000 2015
    #############
    my $time = shift;
    if ($time =~ / /) {$time = localtime Time::Piece->strptime($time, "%a %b %d %T %z %Y");}
    else {$time = localtime Time::Piece->strptime($time, "%Y-%m-%dT%H:%M:%S");}
    return $time->epoch;
}


sub escape{
    $str = shift;
    $out = "";
    while ($str =~/(.)/g){
	if (ord($1)>=128) {$out .= "\\$1";}
	else {$out .= $1;}
    }
    return $out;
}

sub readfile{
    my $file=shift;
    print FERR "Reading output file=$file ";
    open FILE,"<$file" or die "error: cannot open file=$file\n";
    while (<FILE>){
	$lines .= $_;
	if (/^\s*\}\;\s*$/){
	    $t = \%{ eval $lines };
	    $tweet_ids{$t->{id}} = 1 if ($t->{id});
	    $lines = "";
	}
    }
    close FILE;
    print FERR "(".(keys %tweet_ids)." tweets)\n";
}

