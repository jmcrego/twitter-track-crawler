#!/usr/bin/perl

#use strict;
#use warnings;
#require Encode;
#use Data::Dumper;
use HTML::Entities;
use Time::Piece;
use utf8;
#binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

our $SEP="\t";
our $RET="✪"; # &#10030; &#x272e;
our $TAB="❂"; # &#10050; &#x2742;
our $t;
%tweet_ids=();
while (1){
    $t1 = eval &readblock;
    $t = \%{ $t1 };
    $id=$t->{id};
    next if ($tweet_ids{$id});
    $tweet_ids{$id}=1;
    print decode_entities($id.&time.&user.&lang.&favorites.&retweets.&retweet_of.&messg.&geolocation.&hashtags.&urls.&media.&mentions.&symbols."\n");
    if ($t->{retweeted_status}){
        $t = $t->{retweeted_status};
        $id=$t->{id};
        next if ($tweet_ids{$id});
        $tweet_ids{$id}=1;
        print decode_entities($id.&time.&user.&lang.&favorites.&retweets.&retweet_of.&messg.&geolocation.&hashtags.&urls.&media.&mentions.&symbols."\n");
    }
}
sub readblock{
    my $lines;
    while(<>){
        $lines .= $_;
        if (/^\s*\}\;\s*$/) {return $lines;}
    }
    exit; ### end of file
}

sub time{
    my $tp = localtime Time::Piece->strptime( $t->{created_at}, "%a %b %d %T %z %Y")->epoch;
#    return $SEP.$tp->epoch.$SEP."t:".$tp->datetime;
    return $SEP."t:".$tp->datetime;
}
sub user{
    return $SEP."u:".$t->{user}{id}.":".$t->{user}{screen_name};
}
sub lang{
    return $SEP."l:".$t->{lang};
}
sub filter_level{
    if ($t->{filter_level}) {return $SEP."f:".$t->{filter_level};}
    return "";
}
sub geolocation{
    if ($t->{place}{country}){
        my $country_code=$t->{place}{country_code};
        #my $country=$t->{place}{country};
        my $full_name=$t->{place}{full_name};
        #my $name=$t->{place}{name};
        #my $url=$t->{place}{url}
        return $SEP."G:".${full_name}."|".${country_code};
    
    }
}
sub retweets{
    return "" unless (defined $t->{retweet_count});
    return $SEP."R:".$t->{retweet_count};
}
sub favorites{
    return "" unless (defined $t->{favorite_count});
    return $SEP."F:".$t->{favorite_count};
}
sub retweet_of{
    return $SEP."r:"."-1" unless (defined $t->{retweeted_status});
    return $SEP."r:".$t->{retweeted_status}{id};
}
sub hashtags{
    my @res=();
#    foreach my $str (@{$t->{entities}{hashtags}}) {push @res, "H:"."[".join(",",@{$str->{indices}}).")".$str->{text};}
#    if ($#res>=0) {return $SEP.join($SEP,@res);}
#    return "";
    foreach my $str (@{$t->{entities}{hashtags}}) {push @res, "#".$str->{text}."[".join(",",@{$str->{indices}}).")";}
    if ($#res>=0) {return $SEP.join($SEP,@res);}
    return "";
}
sub urls{
    my @res=();
#    foreach my $str (@{$t->{entities}{urls}}) {push @res, "U:"."[".join(",",@{$str->{indices}}).")".$str->{expanded_url};}
#    if ($#res>=0) {return $SEP.join($SEP,@res);}
#    return "";
    foreach my $str (@{$t->{entities}{urls}}) {push @res, "&".$str->{expanded_url}."[".join(",",@{$str->{indices}}).")";}
    if ($#res>=0) {return $SEP.join($SEP,@res);}
    return "";
}
sub media{
    my @res=();
    my %output=();
    foreach my $str (@{$t->{extended_entities}{media}}) {
        next if (exists $output{$str->{url}});
        $output{$str->{url}}=1;
        ### collect features
        my $indices = join(",",@{$str->{indices}});
        my $url;
        if ($str->{type} eq "video") {
            my @urls = @{$str->{video_info}{variants}};
            if ($#urls>=0) {$url=$urls[0]->{url};}
            else {$url=$str->{media_url_https}};
        }
        else {$url=$str->{media_url_https}};
#       push @res, "F:"."[".$indices.")".$str->{type}."=".$url;
        push @res, $str->{type}.$url."[".$indices.")";
    }
#    foreach my $str (@{$t->{entities}{media}})          {push @res, "Z:"."[".join(",",@{$str->{indices}}).")".$str->{media_url_https};}
    if ($#res>=0) {return $SEP.join($SEP,@res);}
    return "";
}
sub mentions{
    my @res=();
#    foreach my $str (@{$t->{entities}{user_mentions}}) {push @res, "M:"."[".join(",",@{$str->{indices}}).")".$str->{id}.":".$str->{screen_name};}
#    if ($#res>=0) {return $SEP.join($SEP,@res);}
    foreach my $str (@{$t->{entities}{user_mentions}}) {push @res, "@".$str->{screen_name}."[".join(",",@{$str->{indices}}).")".":".$str->{id};}
    if ($#res>=0) {return $SEP.join($SEP,@res);}
    return "";
}
sub symbols{
    my @res=();
    foreach my $str (@{$t->{entities}{symbols}}) {push @res, "\$".$str->{text}."[".join(",",@{$str->{indices}}).")";}
    if ($#res>=0) {return $SEP.join($SEP,@res);}
    return "";
}
sub messg{
    my $str = $t->{text};
    $str =~ s/\t/${TAB}/g;
    $str =~ s/\n/${RET}/g;
    $str =~ s/\r/${RET}/g;
    return $SEP."T:".$str;
}
