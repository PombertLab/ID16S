#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'fastq2fasta.pl';
my $version = '0.2a';
my $updated = '2021-04-06';

use strict; use warnings; use Getopt::Long qw(GetOptions); use File::Basename;

## Defining options
my $usage = <<"OPTIONS";
NAME	${name}
VERSION	${version}
UPDATED	${updated}
SYNOPSIS	Converts FASTQ files to FASTA format (no quality scores)

COMMAND	${name} \\
		  -f *.fastq \\
		  -o FASTA \\
		  -v

-f (--fastq)	FASTQ files to convert
-o (--outdir)	Output directory [Default: ./]
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$usage\n" unless @ARGV;

my @fq;
my $outdir = './';
my $verbose;
GetOptions(
	'f|fastq=s@{1,}' => \@fq,
	'o|outdir=s' => \$outdir,
	'v|verbose' => \$verbose
);

## Creating directory
unless (-d $outdir){
	mkdir ($outdir, 0755) or die "Can't create output directory $outdir: $!\n";
}
if ($verbose){ print "\nFASTA output directory: $outdir\n"; }

## Working on fastq files
while (my $fastq = shift@fq){
	open FASTQ, "<", "$fastq" or die "Can't read file: $fastq $!\n";
	my $basename = fileparse($fastq);
	$basename =~ s/.\w+$//;
	open FA, ">", "${outdir}/$basename.fasta" or die "Can't create file: $basename.fasta $!\n";

	my @fastq;
	while (my $line = <FASTQ>){push (@fastq, $line);}
	my $len = scalar@fastq;
	my $read_num = $len/4;
	if ($verbose) { print "Number of reads in $fastq = $read_num\n"; }

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
