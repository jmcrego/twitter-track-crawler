#!/usr/bin/perl

use HTML::Entities;
use Time::Piece;
use utf8;
#binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

$usage="$0 [-i] [-t] [-u] [-l] [-g] [-r] [-R] [-f] [-e] [-all]
   -i : id ({id})
   -t : time/date ({created_at})
   -u : user ({user}{id},{user}{screen_name})
   -l : language ({lang})
   -g : geolocation ({place}{full_name})
   -x : retweet of ({retweeted_status}{id})
   -r : num of retweets ({retweet_count})
   -f : num of favorites ({favorite_count})
   -e : entities (hashtags,mentions,urls,symbols)
   -all : all options
";

while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-h") {print $usage;exit;}
    if ($tok eq "-i") {$do_i=1;next;}
    if ($tok eq "-t") {$do_t=1;next;}
    if ($tok eq "-u") {$do_u=1;next;}
    if ($tok eq "-l") {$do_l=1;next;}
    if ($tok eq "-g") {$do_g=1;next;}
    if ($tok eq "-x") {$do_x=1;next;}
    if ($tok eq "-r") {$do_r=1;next;}
    if ($tok eq "-f") {$do_f=1;next;}
    if ($tok eq "-e") {$do_e=1;next;}
    if ($tok eq "-all") {$do_i=1;$do_t=1;$do_u=1;$do_l=1;$do_g=1;$do_x=1;$do_r=1;$do_f=1;$do_e=1;next;}
    die "error: unparsed $tok option\n$usage";
}

our $SEP="\t";
our $RET="✪"; # &#10030; &#x272e;
our $TAB="❂"; # &#10050; &#x2742;
our $t;

%tweet_ids=();
while (1){
    $t1 = eval &readblock;
    $t = \%{ $t1 };
    &parse;
    #if ($t->{retweeted_status}){$t = $t->{retweeted_status};&parse;}
}
exit;

sub parse{
    next if ($tweet_ids{$t->{id}});
    $tweet_ids{$t->{id}}=1;
    my @messg = split /${SEP}/,&messgEntities($do_e);
    my @line;
    push @line,shift @messg;
    if ($do_i){push @line,"i:".$t->{id};}
    if ($do_t){push @line,"t:".&time;}
    if ($do_u){push @line,"u:".$t->{user}{id}.":".$t->{user}{screen_name};}
    if ($do_l){push @line,"l:".$t->{lang};}
    if ($do_g){push @line,"g:".($t->{place}{id} ? $t->{place}{id}.":".$t->{place}{full_name} : "");}
    if ($do_x){push @line,"x:".$t->{retweeted_status}{id};}
    if ($do_r){push @line,"r:".$t->{retweet_count};}
    if ($do_f){push @line,"f:".$t->{favorite_count};}
    if (scalar @messg){push @line,@messg;}
    print decode_entities(join($SEP,@line)."\n");
}
sub readblock{
    my $lines;
    while(<>){
        $lines .= $_;
        if (/^\s*\}\;\s*$/) {return $lines;}
    }
    exit; ### end of file
}
sub messgEntities{
    my $do_e=shift;
    my $str = $t->{text};
    $str =~ s/\t/${TAB}/g;
    $str =~ s/\n/${RET}/g;
    $str =~ s/\r/${RET}/g;
    my @entities;
    if ($do_e){
	my $N=65;
	my $M=97;
	my @ents;
	push @ents, &hashtags;
	push @ents, &mentions;
	push @ents, &urls;
	push @ents, &symbols;
	foreach $entity (@ents){
	    if ($entity =~ /^(.+)\[(\d+),(\d+)\)/){
		$name=$1;
		$from=$2;
		$to=$3;
		$tag="_".join("",(chr($N) x 5))."_"; 
		if ($str =~ s/${name}/${tag}/i){
		    push @entities,$tag.":".$entity;
		    $N++;
		}
		else{
		    $tag="_".join("",(chr($M) x 5))."_"; 
		    push @entities,$tag.":".$entity;
		    $M++;
		}
	    }
	    else {print STDERR "warning: unparsed entity '$entity' (tweet_id=$t->{id})\n";}
	}
    }
    unshift(@entities,$str);
    return join($SEP,@entities);
}
sub time{
    my $tp = localtime Time::Piece->strptime($t->{created_at}, "%a %b %d %T %z %Y")->epoch;
    return $tp->datetime;
}
sub hashtags{
    my @res=();
    foreach my $str (@{$t->{entities}{hashtags}}) {push @res, "#".$str->{text}."[".join(",",@{$str->{indices}}).")";}
    return @res;
}
sub mentions{
    my @res=();
    foreach my $str (@{$t->{entities}{user_mentions}}) {push @res, "@".$str->{screen_name}."[".join(",",@{$str->{indices}}).")".$str->{id};}
    return @res;
}
sub urls{
    my @res=();
    ### regular urls
    foreach my $str (@{$t->{entities}{urls}}) {push @res, $str->{url}."[".join(",",@{$str->{indices}}).")".$str->{expanded_url};}
    #### media urls
    foreach my $str (@{$t->{entities}{media}}) {push @res, $str->{url}."[".join(",",@{$str->{indices}}).")"."[type=".$str->{type}."]".$str->{media_url};}
    return @res;
}
sub symbols{
    my @res=();
    foreach my $str (@{$t->{entities}{symbols}}) {push @res, $str->{text}."[".join(",",@{$str->{indices}}).")";}
    return @res;
}
