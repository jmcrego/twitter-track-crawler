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
    print decode_entities($id.&time.&user.&lang.&favorites.&retweets.&retweet_of.&geolocation.&messgEntities."\n");
    if ($t->{retweeted_status}){
        $t = $t->{retweeted_status};
        $id=$t->{id};
        next if ($tweet_ids{$id});
        $tweet_ids{$id}=1;
        print decode_entities($id.&time.&user.&lang.&favorites.&retweets.&retweet_of.&geolocation.&messgEntities."\n");
    }
}

sub messgEntities{
    my $str = $t->{text};
    $str =~ s/\t/${TAB}/g;
    $str =~ s/\n/${RET}/g;
    $str =~ s/\r/${RET}/g;
    my @entities=();
    my $N=65;
    my @ents=&hashtags;
    push @ents, &mentions;
    push @ents, &urls;
    push @ents, &symbols;
#    print "\tmessg1=$str\n";
    foreach $entity (@ents){
        if ($entity =~ /^(.+)\[(\d+),(\d+)\)/){
	    $name=$1;
	    $from=$2;
	    $to=$3;
	    $tag="_".join("",(chr($N) x 5))."_";
	    if ($str =~ s/${name}/${tag}/i){
#		print "\t\tREPLACE '$name' => '$tag'\n";
		push @entities,$tag."=".$entity;
		$N++;
	    }
	    else{
#		print STDERR "warning: unfound entity '${name}[${from},${to})' (tweet_id=$t->{id})\n";
	    }
	}
	else{
#	    print STDERR "warning: unparsed entity '$entity' (tweet_id=$t->{id})\n";
	}
    }
#    print "\tmessg2=$str\n";
    return $SEP.$str.$SEP.join($SEP,@entities);
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
    return $SEP."G:"."-1" unless (defined $t->{place}{country});
    return $SEP."G:".$t->{place}{full_name}."|".$t->{place}{country_code};
    #my $t->{place}{country};
    #my $t->{place}{name};
    #my $t->{place}{url}
}
sub retweets{
    return $SEP."R:-1" unless (defined $t->{retweet_count});
    return $SEP."R:".$t->{retweet_count};
}
sub favorites{
    return $SEP."F:-1" unless (defined $t->{favorite_count});
    return $SEP."F:".$t->{favorite_count};
}
sub retweet_of{
    return $SEP."r:"."-1" unless (defined $t->{retweeted_status});
    return $SEP."r:".$t->{retweeted_status}{id};
}




sub hashtags{
    my @res=();
    foreach my $str (@{$t->{entities}{hashtags}}) {push @res, "#".$str->{text}."[".join(",",@{$str->{indices}}).")";}
    return @res;
}
sub mentions{
    my @res=();
    foreach my $str (@{$t->{entities}{user_mentions}}) {push @res, "@".$str->{screen_name}."[".join(",",@{$str->{indices}}).")".":".$str->{id};}
    return @res;
}
sub urls{
    my @res=();
    ### regular urls
    foreach my $str (@{$t->{entities}{urls}}) {push @res, $str->{url}."[".join(",",@{$str->{indices}}).")".":".$str->{expanded_url};}
    #### media urls
    foreach my $str (@{$t->{entities}{media}}) {push @res, $str->{url}."[".join(",",@{$str->{indices}}).")".":".$str->{type}.":".$str->{media_url};}
    return @res;
}
sub symbols{
    my @res=();
    foreach my $str (@{$t->{entities}{symbols}}) {push @res, $str->{text}."[".join(",",@{$str->{indices}}).")";}
    return @res;
}
