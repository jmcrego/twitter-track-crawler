#!/usr/bin/perl

use Net::Twitter;
use Data::Dumper;
use utf8;
binmode STDOUT,':utf8';

$nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
    );

print Dumper $nt->trends_available();
exit;
