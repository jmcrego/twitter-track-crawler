#!/usr/bin/perl

use Net::Twitter;
use AnyEvent::Twitter::Stream;
use Data::Dumper;
use Encode;
use IO::Handle;
use utf8;
use Time::localtime;
use Time::Piece;
binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

$usage="$0 -w \"STRING\" -a STRING -o FILE -l LANGS
   -w STRING : comma-separated list of words to track (Ex \"eruption,earthquake,tsunami\")
   -a STRING : app used {crawl1,crawl2,crawl3}
   -o STRING : file name
   -l LANGS  : comma-separated list of languages

Example:
   $0 -w \"eruption,earthquake,tsunami\" -a crawl1 -o ./track.naturaldisaster -l en &

adapted from: https://github.com/miyagawa/AnyEvent-Twitter-Stream
";

while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-w" && $#ARGV>=0) {$track=shift @ARGV; next;}
    if ($tok eq "-a" && $#ARGV>=0) {$app=shift @ARGV; next;}
    if ($tok eq "-o" && $#ARGV>=0) {$fout=shift @ARGV; next;}
    if ($tok eq "-l" && $#ARGV>=0) {$language=shift @ARGV; next;}
    die "error: unparsed '$tok' option\n$usage";
}
die "error: missing options\n$usage" unless (defined $track && defined $app && defined $fout && defined $language);
$track=&escape($language,decode("utf-8",$track));

my ($consumer_key,$consumer_secret,$token,$token_secret) = &application($app);
$fout .= "___".$language."___".$app."___".&time;
$fout =~ s/ /\_/g;

open(FOUT,">$fout.tweets") or die "error: cannot open fout: $fout.tweets\n";
binmode FOUT, ':utf8';
open(FLOG,">$fout.log") or die "error: cannot open flog: $fout.log\n";
binmode FLOG, ':utf8';

print FLOG "app\t$app\n\t$consumer_key\n\t$consumer_secret\n\t$token\n\t$token_secret\n";
print FLOG "track\t$track\n";
print FLOG "lang\t$language\n";
print FLOG "fout\t$fout.tweets\n";
FLOG->autoflush;

############################################################################
### MAIN LOOP ##############################################################
############################################################################

$done = AnyEvent->condvar;
$listener = AnyEvent::Twitter::Stream->new(
    consumer_key    => $consumer_key,
    consumer_secret => $consumer_secret,
    token           => $token,
    token_secret    => $token_secret,
    on_tweet        => sub {print FOUT Dumper(shift);FOUT->autoflush;},
    on_delete       => sub {print FLOG "delete [".shift."] (user_id=".shift.") @ ".ctime()."\n";FLOG->autoflush;},
    on_error        => sub {print FLOG "error [".shift."] @ ".ctime()."\nsleep 90\n";FLOG->autoflush;sleep 90;},
    on_keepalive    => sub {print FLOG "keepalive [".shift."] @ ".ctime()."\n";FLOG->autoflush;},
    on_connect      => sub {print FLOG "connect [".shift."] @ ".ctime()."\n";FLOG->autoflush;},
    on_eof          => sub {print FLOG "eof [".shift."] @ ".ctime()."\n";FLOG->autoflush;},
    timeout         => 90,
    method          => filter,
    filter_level    => none,
    language        => $language,
    track           => $track,
    );
$done->recv;
#    locations => $locations,
#    place => $place,
#    follow => $follow,

###########################################################################
############################################################################
############################################################################

close FOUT;
close FLOG;
exit;

sub application{
    my $app = shift @_;
    $consumer_key1    = 'KnzpHso9d7qXfXT72Y0sly360';
    $consumer_secret1 = 'mQbryk7RInrRp3QZuSkqH4U59H4NsWQj4X8pWFspajklbirCFS';
    $token1           = '3288314879-pysLtV3l1CnMo3hvRWaGf1KggPQP2xr4SqqcsFy';
    $token_secret1    = 'jSGfcnlJAGxZLfbx7CbjGFSDPHP4i7u0NA0UqsU8f60qO';

    $consumer_key2    = 'zLQRN4RKE3xBJCDpErbgWWVUO';
    $consumer_secret2 = 'M9ezYeQEm5WP84kXycbNA7Zo74lG8DS4gj86THKOzacT1yTBqC';
    $token2           = '3288314879-dgIk2nZV9yULyllrG9KeFkonoJNdrNZBbkh62VC';
    $token_secret2    = 'HYiIJYnxvPoaZsW9awDKOSKiNcuE2ofyMteSEQwCbVmBQ';

    $consumer_key3    = 'GvttngR56jlsfhMUWJUVvETA4';
    $consumer_secret3 = 'hGssqX4gKZoeRHLMjWJoF1yxBiztim6maP9LwW8HywlPTUbZLy';
    $token3           = '3288314879-LSv3c8BA1lW4lkYMr2zDHQ2Hj1Etmh9dlV42rSM';
    $token_secret3    = '565L2zzP8nPeDgO9webK6VsvoYn0T5BK6bTrcUBgGoXOU';

    my @result;
    if ($app eq "crawl1"){
        push @result, $consumer_key1;
        push @result, $consumer_secret1;
        push @result, $token1;
        push @result, $token_secret1;
    }
    elsif ($app eq "crawl2"){
        push @result, $consumer_key2;
        push @result, $consumer_secret2;
        push @result, $token2;
        push @result, $token_secret2;
    }
    elsif ($app eq "crawl3"){
        push @result, $consumer_key3;
        push @result, $consumer_secret3;
        push @result, $token3;
        push @result, $token_secret3;
    }
    else{
        die "unparsed -a option\n$usage";
    }
    return @result;
}

sub escape{
    $lng = shift;
    $str = shift;
#    return $str if ($lng eq "ar");
    $out = "";
    while ($str =~/(.)/g){
        if (ord($1)>=128) {$out .= "\\$1";}
        else {$out .= $1;}
    }
    return $out;
}

sub time{
    $now=ctime();#Wed May 13 09:36:24 2015
    $now = (localtime Time::Piece->strptime($now, "%a %b %d %T %Y"))->datetime;#2015-05-13T09:52:59
    $now =~ s/[\-\:]/\_/g;
    $now =~ s/T/\-/;#2015_05_13-09_52_59
    return $now;
}

