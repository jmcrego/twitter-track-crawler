#!/usr/bin/perl

while (<>){
    chomp;
    @toks = split /\t/;
    $messg=$toks[8];
    for ($i=9; $i<=$#toks; $i++){
	$ent=$toks[$i];
	if ($ent =~ /^(.)(.+)\[(\d+),(\d+)\)$/){
	    $type=$1;
	    $name=$2;
	    $from=$3;
	    $to=$4;
	    $messg =~ s/${ent}/${type}${i}/;
	}
    }
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
