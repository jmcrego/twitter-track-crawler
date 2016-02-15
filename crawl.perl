#!/usr/bin/perl

use Scalar::Util 'blessed';
use List::Util qw(min max);
use Net::Twitter;
use Data::Dumper;
use Time::localtime;
use Time::Piece;
use utf8;
use Encode;

binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

for ($i=0; $i<=$#ARGV; $i++) {$ARGV[$i] = decode("utf-8", $ARGV[$i]);}
$parameters="@ARGV";

$_count        = 100;
$_rtype        = "recent";
$_since_id     = 0;
$_max_requests = 180;

$help="
Tweets (timelines) flow over time:
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

$usage="$0 -k FILE (query OR geolocation OR trends)
           -q \"STRING\" -l LANG [-s ID] [-m INT] (query)
           -g                                   (geolocation)
           -t WOEID                             (trends)
   -k FILE   : key file
   -q STRING : list of terms in query mode (Ex: \"earthquake OR extreme heat\")
   -Q STRING : file with list of terms in query mode (one line each term)
   -g        : geolocation mode
   -t WOEID  : WOEID in trends mode
   -l LANG   : language (default: not used)
   -s ID     : since_id
   -m N      : max number of requests
   -h        : help message
";

while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-g") {$_geolocation=1; next;} 
    if ($tok eq "-t" && $#ARGV>=0) {$_trends=shift @ARGV; next;} 
    if ($tok eq "-q" && $#ARGV>=0) {$_query=shift @ARGV; next;} 
    if ($tok eq "-Q" && $#ARGV>=0) {$_fquery=shift @ARGV; next;} 
    if ($tok eq "-l" && $#ARGV>=0) {$_lang=shift @ARGV; next;} 
    if ($tok eq "-k" && $#ARGV>=0) {$_fkey=shift @ARGV; next;} 
    if ($tok eq "-s" && $#ARGV>=0) {$_since_id=shift @ARGV; next;} 
    if ($tok eq "-m" && $#ARGV>=0) {$_max_requests=shift @ARGV; next;} 
    if ($tok eq "-h") {print $usage.$help."\n"; exit;} 
    die "error: unparsed '$tok' option\n$usage";
}

die "error: missing -k option\n$usage" unless (defined $_fkey);
my ($ckey,$csecret,$tok,$tsecret) = &application($_fkey);
my $nt = Net::Twitter->new(traits=>[qw/API::RESTv1_1/], consumer_key=>$ckey, consumer_secret=>$csecret, access_token=>$tok, access_token_secret=>$tsecret, ssl=>1);

if (defined $_trends){
    print Dumper $nt->trends_place($_trends);
#    $r = $nt->trends_place($_trends);
#    foreach $entry (@{$r}){
#	print $entry->{created_at}."\n";
#	foreach $trend (@{$entry->{trends}}){
#	    print $trend->{name}."\n";
#	}
#    }
    exit;
}
elsif (defined $_geolocation){
    print Dumper $nt->trends_available();
#    $r = $nt->trends_available();
#    foreach $entry (@{$r}){
#	print "$entry->{name}:$entry->{country}\t$entry->{woeid}\t$entry->{placeType}{name}\n";
#    }
    exit;
}
elsif (defined $_query){
    die "error: missing -l option\n$usage" unless (defined $_lang);
}
elsif (defined $_fquery){
    die "error: missing -l option\n$usage" unless (defined $_lang);
    open (FILE,"<$_fquery") or die "error: cannot open fquery file=$_fquery\n";
    binmode FILE, ':utf8';
    while (<FILE>){
	chomp;
	next if (/^\s*$/);
	next if (/^ /);
	push @QUERY, $_;
    }
    close FILE;
    $_query=join(" OR ",@QUERY);
}
else{
   die "error: missing -q OR -g OR -t options\n$usage";
}

print STDERR "RUN: $0 $parameters\n";
my $status=$nt->rate_limit_status({ authenticate => 1 });
my $nrequestsremaining=$status->{"resources"}{"search"}{"/search/tweets"}{"remaining"};

my %query=();
$query{"q"}=$_query;
$query{"lang"}=$_lang;
$query{"result_type"}=$_rtype;
$query{"count"}=$_count;
$query{"since_id"}=$_since_id if ($_since_id>0);

$nrequests=0;
while (true){
    die "[END] no requests available!\n" unless ($nrequestsremaining>0);
    die "[END] max requests=$nrequests reached!\n" if ($nrequests>=$_max_requests);
    $now=&whattimeisit;
    my $r;
    eval { $r = $nt->search(\%query) };
    if ( my $err = $@ ){
	die "[KO] error: $err\n" unless (blessed $err && $err->isa('Net::Twitter::Error'));
	die "[KO] error: HTTP Response Code:".$err->code." HTTP Message:".$err->message." Twitter error:".$err->error."\n";
    }
    $nrequestsremaining--;
    $nrequests++;
    my $curr_first_date=0;
    my $curr_first_id=0;
    my $curr_last_date=0;
    my $curr_last_id=0;
    foreach $entry (@{$r->{statuses}}){
	my $id = $entry->{id};
	if ($id>$most_recent_id){
	    $most_recent_id=$id;
	    print STDERR "recent_id=$most_recent_id\n";
	}
	if ($curr_first_id==0 || $id<$curr_first_id){
	    $curr_first_id=$id;
	    $time = localtime Time::Piece->strptime( $entry->{created_at}, "%a %b %d %T %z %Y")->epoch;
	    $curr_first_date=$time->datetime;
	}
	if ($curr_last_id==0 || $id>$curr_last_id){
	    $curr_last_id=$id;
	    $time = localtime Time::Piece->strptime( $entry->{created_at}, "%a %b %d %T %z %Y")->epoch;
	    $curr_last_date=$time->datetime;
	}
	print Dumper($entry);
    }
    $dumped=Dumper(\%query); $dumped=~s/[\n\s]+/ /g; print STDERR "($now) $dumped\n";
    my $nstatuses=scalar(@{$r->{statuses}});
    die "[END] since_id REACHED ($_since_id)\n" if ($_since_id && $curr_first_id<=$_since_id);
    ### OK
    print STDERR "[OK] $nstatuses [$curr_first_id,$curr_last_id] [$curr_first_date,$curr_last_date] remain=$nrequestsremaining\n";
    exit unless ($nstatuses);
    if ($curr_first_id) {$query{"max_id"}=$curr_first_id-1;}
}
exit;

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
