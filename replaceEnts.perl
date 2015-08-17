#!/usr/bin/perl

while (<>){
    chomp;
    @toks = split /\t/;
    $messg=$toks[8];
    print "\tmessg1=$messg\n";
    for ($i=9; $i<=$#toks; $i++){
	$ent=$toks[$i];
	if ($ent =~ /^(.+)\[\d+,\d+\)$/){
	    $name=$1;
	    print "\t\tent[$i] name=$name ==> $ent\n";
	    $messg =~ s/\Q${name}\E/___${i}___/;
	}
    }
    print "\tmessg2=$messg\n";
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
