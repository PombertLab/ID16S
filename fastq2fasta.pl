#!/usr/bin/perl
## Pombert Lab, 2018
## Converts FASTQ files to FASTA format (no quality scores)

use strict;
use warnings;

die "\nUSAGE = fastq2fasta.pl *.fastq\n\n" unless @ARGV;

while (my $fastq = shift@ARGV){
	open FASTQ, "<$fastq";
	$fastq =~ s/.fastq$//; $fastq =~ s/.fq$//;
	open FA, ">$fastq.fasta";
	my @fastq;
	while (my $line = <FASTQ>){push (@fastq, $line);}
	my $len = scalar@fastq;
	my $read_num = $len/4;
	print "Number of reads in $fastq = $read_num\n";
	my $count;
	for (0..$read_num-1){
		$count = 1+(4*$_);
		my $fs = $count-1;
		## Keeping only 1st part of sequence names before whitespaces
		my $name = $fastq[$fs];
		if ($name =~ /^@(\S+)/){print FA ">$1\n";} 
		## Printing sequence
		my @fasta = unpack ("(A60)*", $fastq[$count]);
		while (my $tmp = shift@fasta){print FA "$tmp\n";}
	}
}
