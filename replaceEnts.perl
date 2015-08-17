#!/usr/bin/perl

while (<>){
    chomp;
    @toks = split /\t/;
    $messg=$toks[8];
    print "\tmessg1=$messg\n";
    for ($i=9; $i<=$#toks; $i++){
	$ent=$toks[$i];
	if ($ent =~ /^(.)(.+)\[\d+,\d+\)$/){
	    $type=$1;
	    $name=$2;
	    print "\t\tent[$i] type=$type name=$name ==> $ent\n";
	    $messg =~ s/\Q${type}${name}\E/${type}${i}${type}/;
	}
    }
    print "\tmessg2=$messg\n";
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
