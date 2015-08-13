#!/usr/bin/perl

use Net::Twitter;
use Data::Dumper;
use Encode;
use utf8;
binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

$consumer_key    = '1S6WuT1cHb1aheXgIMyc2MOpx';
$consumer_secret = 'KmCP00Fhwzb5pWcZZUe2bXK9jj6SA18fLziyN7DViR8Ml2QVRW';
$token           = '245973415-guYTAXRlctmsN0cWvuZuZvs03f0H5FZpcEnz7QFJ';
$token_secret    = 'Xy5bCBCaj1IWsKF1VQ3ZiFGMHRc0MOGxHxN9W2huq5Xg1'; 

$usage="$0 [-f FILE -l STRING] [-i WOEID]
   -f FILE   : file with dumped locations
   -l STRING : Type=Location (Ex Town=Paris=France)
   -i WOEID  : woeid to retrieve (Ex 615702)
";

while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-f" && $#ARGV>=0) {$file=shift @ARGV; next;} 
    if ($tok eq "-l" && $#ARGV>=0) {$loc=&escape(decode("utf-8",shift @ARGV)); next;} 
    if ($tok eq "-i" && $#ARGV>=0) {$id=shift @ARGV; next;} 
    die "error: unparsed '$tok' option\n$usage";
}
die "\nerror: missing -f option\n$usage" unless (defined $file);
die "\nerror: EITHER -l OR -i options\n$usage" unless (defined $loc || defined $id);
die "\nerror: EITHER -l OR -i options\n$usage" if (defined $loc && defined $id);

($id,$loc) = split /\t/, &loadfile($file);

$nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
    ssl                 => 1,  ## enable SSL! ##
    );

$r = $nt->trends_place($id);#print Dumper ($r);
foreach $entry (@{$r}){
    print $entry->{created_at}."\n";
    foreach $trend (@{$entry->{trends}}){
	print $trend->{name}."\n";
    }
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

sub loadfile{
    $file = shift;
    $r = eval `cat $file`;
    foreach $entry (@{$r}){
	$id=$entry->{woeid} if (defined $loc && $entry->{placeType}{name}."=".$entry->{name}."=".$entry->{country} eq $loc);
	$loc=$entry->{placeType}{name}."=".$entry->{name}."=".$entry->{country} if (defined $id && $entry->{woeid} eq $id)
    }
    die "error: could not find location '$loc' in file=$file\n" unless (defined $id);
    print $id."=".$loc."\n";
    return $id."\t".$loc;
}
