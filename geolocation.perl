#!/usr/bin/perl

use Net::Twitter;
use Data::Dumper;
use utf8;
binmode STDOUT,':utf8';

$consumer_key    = '1S6WuT1cHb1aheXgIMyc2MOpx';
$consumer_secret = 'KmCP00Fhwzb5pWcZZUe2bXK9jj6SA18fLziyN7DViR8Ml2QVRW';
$token           = '245973415-guYTAXRlctmsN0cWvuZuZvs03f0H5FZpcEnz7QFJ';
$token_secret    = 'Xy5bCBCaj1IWsKF1VQ3ZiFGMHRc0MOGxHxN9W2huq5Xg1'; 

$nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
    );

print Dumper $nt->trends_available();
exit;
