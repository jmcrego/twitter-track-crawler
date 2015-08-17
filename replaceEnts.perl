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
	    if ($type eq "&") {$messg =~ s/\Q${name}\E/___${i}___/;}
	    else {$messg =~ s/\Q${type}${name}\E/___${i}___/;}
	}
    }
    print "\tmessg2=$messg\n";
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
