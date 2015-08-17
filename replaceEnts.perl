#!/usr/bin/perl

while (<>){
    chomp;
    @toks = split /\t/;
    $messg=$toks[8];
#    print "\tmessg1=$messg\n";
    for ($i=9; $i<=$#toks; $i++){
	$ent=$toks[$i];
	if ($ent =~ /^(.+)\[(\d+),(\d+)\)/){
	    $name=$1;
	    $from=$2;
	    $to=$3;
	    $size=$to-$from;
	    $letters = join("",("_") x $size);
#	    print "\t\treplacing '$name'\n";
	    $messg =~ s/${name}/${letters}/i;
	}
    }
#    print "\tmessg2=$messg\n";
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
