#!/usr/bin/perl

use HTML::Entities;
use Time::Piece;
use utf8;
#binmode STDIN, ':utf8';
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

our $SEP="\t";
our $RET="✪"; # &#10030; &#x272e;
our $TAB="❂"; # &#10050; &#x2742;
our $noRT=0;
our $noTAG=0;
our $noU=0;
our $noM=0;
our $noH=0;
our %Block;
$usage="$0 [-m] [-i] [-t] [-u] [-l] [-g] [-r] [-R] [-f] [-e] [-sep STRING] [-noRT] [-noM] [-noU] [-noH] [-block FILE] [-RET STRING] [-TAB STRING]
   -m          : message ({text})
   -i          : id ({id})
   -t          : time/date ({created_at})
   -u          : user ({user}{id},{user}{screen_name})
   -l          : language ({lang})
   -g          : geolocation ({place}{full_name})
   -x          : retweet of ({retweeted_status}{id})
   -r          : num of retweets ({retweet_count})
   -f          : num of favorites ({favorite_count})
   -e          : entities (hashtags,mentions,urls,symbols)
   -sep STRING : string used to separate columns (example: \$'\\n'\$'\\t' default: \$'\\t') 
   -noRT       : do not consider retweets
   -noM        : do not consider tweets with mentions
   -noU        : do not consider tweets with urls
   -noH        : do not consider tweets with hashtags
   -block FILE : file with list of blocked users
   -noTAG      : do not use column tags
   -RET STRING : replace a [return] by STRING (default $RET)
   -TAB STRING : replace a [tab] by STRING (default $TAB)
";


while ($#ARGV>=0){
    $tok = shift @ARGV;
    if ($tok eq "-h") {print $usage;exit;}
    if ($tok eq "-m") {$do_m=1;push @DO,"m";next;}
    if ($tok eq "-i") {$do_i=1;push @DO,"i";next;}
    if ($tok eq "-t") {$do_t=1;push @DO,"t";next;}
    if ($tok eq "-u") {$do_u=1;push @DO,"u";next;}
    if ($tok eq "-l") {$do_l=1;push @DO,"l";next;}
    if ($tok eq "-g") {$do_g=1;push @DO,"g";next;}
    if ($tok eq "-x") {$do_x=1;push @DO,"x";next;}
    if ($tok eq "-r") {$do_r=1;push @DO,"r";next;}
    if ($tok eq "-f") {$do_f=1;push @DO,"f";next;}
    if ($tok eq "-e") {$do_e=1;push @DO,"e";next;}
    if ($tok eq "-sep" && $#ARGV>=0) {$SEP=shift @ARGV;next;}
    if ($tok eq "-noRT") {$noRT=1;next;}
    if ($tok eq "-noM")  {$noM=1;next;}
    if ($tok eq "-noU")  {$noU=1;next;}
    if ($tok eq "-noH")  {$noH=1;next;}
    if ($tok eq "-noTAG"){$noTAG=1;next;}
    if ($tok eq "-RET" && $#ARGV>=0) {$RET=shift @ARGV;next;}
    if ($tok eq "-TAB" && $#ARGV>=0) {$TAB=shift @ARGV;next;}
    if ($tok eq "-block" && $#ARGV>=0) {
	$fblock=shift @ARGV;
	open (FILE,"<$fblock") or die "error: cannot open block file=$fblock\n";
	while (<FILE>) {chomp;$Block{$_}=1;}
	close FILE;
	next;
    }
    die "error: unparsed $tok option\n$usage";
}

our $t;
%tweet_ids=();
while (1){
    $t1 = eval &readblock;
    $t = \%{ $t1 };
    next if ($noRT && $t->{retweeted_status});
    next if ($noM  && scalar @{$t->{entities}{user_mentions}});
    next if ($noU  && scalar @{$t->{entities}{urls}});
    next if ($noU  && scalar @{$t->{entities}{media}});
    next if ($noH  && scalar @{$t->{entities}{hashtags}});
    next if (keys %Block && exists $Block{$t->{user}{screen_name}});
    &parse;
    #if ($t->{retweeted_status}){$t = $t->{retweeted_status};&parse;}
}
exit;

sub parse{
#    next if ($tweet_ids{$t->{id}});
#    $tweet_ids{$t->{id}}=1;
    my ($messg,$ents) = split /\t/,&messgEntities($do_e);
    
    my @line;
    foreach $todo (@DO){
	if    ($todo eq "m") {push @line,($noTAG?"":"m:").$messg;}
	elsif ($todo eq "i") {push @line,($noTAG?"":"i:").$t->{id};}
	elsif ($todo eq "t") {
	    my $tp = localtime Time::Piece->strptime($t->{created_at}, "%a %b %d %T %z %Y")->epoch;
	    push @line,($noTAG?"":"t:").$tp->datetime;
	}
	elsif ($todo eq "u"){push @line,($noTAG?"":"u:").$t->{user}{id}.":".$t->{user}{screen_name};}
	elsif ($todo eq "l"){push @line,($noTAG?"":"l:").$t->{lang};}
	elsif ($todo eq "g"){push @line,($noTAG?"":"g:").($t->{place}{id}        ? $t->{place}{id}.":".$t->{place}{full_name} : "-");}
	elsif ($todo eq "x"){push @line,($noTAG?"":"x:").($t->{retweeted_status} ? $t->{retweeted_status}{id}                 : "-");}
	elsif ($todo eq "r"){push @line,($noTAG?"":"r:").$t->{retweet_count};}
	elsif ($todo eq "f"){push @line,($noTAG?"":"f:").$t->{favorite_count};}
	elsif ($todo eq "e"){push @line,($noTAG?"":"e:").$ents;}
    }
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
    return "$str\t@entities";
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
