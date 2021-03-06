#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'fastq2fasta.pl';
my $version = '0.1';
my $updated = '06/03/2021';

use strict; use warnings; use Getopt::Long qw(GetOptions);

## Defining options
my $usage = <<"OPTIONS";
NAME	${name}
VERSION	${version}
UPDATED	${updated}
SYNOPSIS	Converts FASTQ files to FASTA format (no quality scores)

COMMAND	${name} -f *.fastq

-f (--fastq)	FASTQ files to convert
OPTIONS
die "\n$usage\n" unless @ARGV;

my @fq;
GetOptions(
	'f|fastq=s@{1,}' => \@fq
);

## Working on fastq files
while (my $fastq = shift@fq){
	open FASTQ, "<", "$fastq" or die "Can't read file: $fastq $!\n";
	$fastq =~ s/.\w+$//;
	open FA, ">", "$fastq.fasta" or die "Can't create file: $fastq.fasta $!\n";

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
