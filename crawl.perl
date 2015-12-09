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

$_count       = 100;
$_rtype       = "recent";
$_since_id    = 0;

$usage="$0 -q \"STRING\" -k FILE -l LANG -s ID
   -q STRING : list of terms (Ex: \"earthquake OR extreme heat\")
   -l LANG   : language (default: not used)
   -k FILE   : key file
   -s ID     : since_id

Tweets (timelines) flow over time like:
lower IDs                                    higher IDs
--------------------------------------------->
PAST                                         PRESENT

Using -s ID we can prevent from retrieving tweets older than a given ID
-----------------[--------------------------->
                 since_id

On each fetch (tweeter search call) we retrieve tweet IDs bounded by [from first_id,last_id]
------------------------------[-----------]-->
                              first_id    last_id

Hence, on succeeding fetchs we use max_id to prevent tweets newer than a given ID (first_id of previous fetch)
---------------------------------[--------]-->
-----------------------------[---]----------->
-----------------------[-----]--------------->
";

while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-q" && $#ARGV>=0)  {$_query=&escape(decode("utf-8",shift @ARGV)); next;} 
#    if ($tok eq "-q" && $#ARGV>=0) {$_query=decode("utf-8",shift @ARGV); next;} 
    if ($tok eq "-l" && $#ARGV>=0)  {$_lang=shift @ARGV; next;} 
    if ($tok eq "-k" && $#ARGV>=0)  {$_fkey=shift @ARGV; next;} 
    if ($tok eq "-s" && $#ARGV>=0)  {$_since_id=shift @ARGV; next;} 
    die "error: unparsed '$tok' option\n$usage";
}
die "error: missing -q option\n$usage" unless (defined $_query);
die "error: missing -l option\n$usage" unless (defined $_lang);
die "error: missing -k option\n$usage" unless (defined $_fkey);

my ($ckey,$csecret,$tok,$tsecret) = &application($_fkey);
my $nt = Net::Twitter->new(traits => [qw/API::RESTv1_1/], consumer_key => $ckey, consumer_secret => $csecret, access_token => $tok, access_token_secret => $tsecret, ssl => 1);
my $status=$nt->rate_limit_status({ authenticate => 1 });
my $nrequestsremaining=$status->{"resources"}{"search"}{"/search/tweets"}{"remaining"};

my %query=();
$query{"q"}=$_query;
$query{"lang"}=$_lang;
$query{"result_type"}=$_rtype;
$query{"count"}=$_count;
$query{"since_id"}=$_since_id if ($_since_id>0);

while (true){
    die "[END] error: $nrequests requests already sent!\n" unless ($nrequestsremaining>0);
    $now=&whattimeisit;
    my $r;
    eval { $r = $nt->search(\%query) };
    if ( my $err = $@ ){
	die "[KO] error: $err\n" unless (blessed $err && $err->isa('Net::Twitter::Error'));
	die "[KO] error: HTTP Response Code:".$err->code." HTTP Message:".$err->message." Twitter error:".$err->error."\n";
    }
    $nrequestsremaining--;
    my $curr_first_id=0;
    my $curr_last_id=0;
    foreach $entry (@{$r->{statuses}}){
	my $id = $entry->{id};
	if ($id>$most_recent_id){
	    $most_recent_id=$id;
	    print STDERR "recent_id=$most_recent_id\n";
	}
	$curr_first_id=$id if ($curr_first_id==0 || $id<$curr_first_id);
	$curr_last_id=$id if ($curr_last_id==0 || $id>$curr_last_id);
	print Dumper($entry);
    }
####
    $dumped=Dumper(\%query); $dumped=~s/[\n\s]+/ /g; print STDERR "($now) $dumped\n";
    my $nstatuses=scalar(@{$r->{statuses}});
    print STDERR "[OK] $nstatuses since_id=".($query{"since_id"})." max_id=".($query{"max_id"})." => [$curr_first_id,$curr_last_id] remain=$nrequestsremaining\n";
    die "[KO] error: 0 statuses fetched!\n" unless ($nstatuses);
    die "[END] since_id REACHED ($_since_id)\n" if ($_since_id && $curr_first_id<=$_since_id);
    $query{"max_id"}=$curr_first_id-1 if ($curr_first_id);
}
exit;

sub escape{
    $str = shift;
    $out = "";
    while ($str =~/(.)/g){
	if (ord($1)>=128) {$out .= "\\$1";}
	else {$out .= $1;}
    }
    return $out;
}

sub application{
    my $fkey = shift @_;
    open (FILE,"<$fkey") or die "error: cannot open keys file: $fkey\n";
    @keys = <FILE>;
    chomp @keys;
    close FILE;
    return @keys;
}

sub whattimeisit{
    my $now = ctime();#Wed May 13 09:36:24 2015
    $now = (localtime Time::Piece->strptime($now, "%a %b %d %T %Y"))->datetime;#2015-05-13T09:52:59
    $now =~ s/[\-\:]/\_/g;
    $now =~ s/T/\-/;#2015_05_13-09_52_59
    return $now;
}
