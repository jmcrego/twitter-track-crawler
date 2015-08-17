#!/usr/bin/perl

while (<>){
    chomp;
    @toks = split /\t/;
    $messg=$toks[8];
#    print "\tmessg1=$messg\n";
    for ($i=9; $i<=$#toks; $i++){
#	print "\t\t[$i] '$toks[$i]'\n";
	if ($toks[$i] =~ /^(_[A-Z]_)=(.+)\[(\d+),(\d+)\)$/){
	    $tag=$1;
	    $name=$2;
	    $messg =~ s/${name}/${tag}/i;
#	    print "\t\t\t'$name' ===> $tag\n";
	}
    }
#    print "\tmessg2=$messg\n";
    $toks[8]=$messg;
    print join("\t",@toks)."\n";
}
