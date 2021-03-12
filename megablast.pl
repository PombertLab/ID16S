#!/usr/bin/perl
## Pombert Lab, IIT 2018
my $name = 'megablast.pl';
my $version = '0.3';
my $updated = '12/03/2021';

use strict; use warnings; use Getopt::Long qw(GetOptions); use File::Basename;

my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Performs homology searches using BLAST and returns results with taxonomic metadata

REQUIREMENTS	- BLAST 2.2.28+ or later
		- NCBI taxonomy database (ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz)
		- The BLASTDB variable must be set: export BLASTDB=/path/to/NCBI/TaxDB

USAGE		${name} \\
		  -k megablast \\
		  -q Examples/sample_1.fasta \\
		  -d NCBI_16S/16S_ribosomal_RNA \\
		  -e 1e-05 \\
		  -c 10 \\
		  -t 10 \\
		  -o MEGABLAST \\
		  -v

OPTIONS:
-k (--task)	megablast, dc-megablast, blastn [default = megablast]
-d (--db)	NCBI 16S Microbial Database to query [default = 16S_ribosomal_RNA]
-t (--threads)	CPUs to use [default = 10]
-e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
-c (--culling)	culling limit [default = 10]
-q (--query)	fasta file(s) to be queried
-o (--outdir)	Output directory [Default: ./]
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$usage\n" unless@ARGV;

## Defining options
my $task = 'megablast';
my $db = '16S_ribosomal_RNA';
my $threads = '2';
my $evalue = '1e-05';
my $culling = '1';
my @query = ();
my $outdir = './';
my $verbose;

GetOptions(
    'k|task=s' => \$task,
	'd|db=s' => \$db,
	't|threads=i' => \$threads,
	'e|evalue=s' => \$evalue,
	'c|culling=i' => \$culling,
	'q|query=s@{1,}' => \@query,
	'o|outdir=s' => \$outdir,
	'v|verbose' => \$verbose
);

## Creating output directory
unless (-e $outdir){
	mkdir ($outdir, 0755) or die "Can't create output directory $outdir: $!\n";
}
if ($verbose){ print "\nBLAST output directory: $outdir\n"; }

## Running BLAST homology searches
while (my $query = shift@query){
	my $basename = fileparse($query);

	## Running BLAST
	if ($verbose){ print "Running $task on $query...\n";}
	system "blastn \\
		-task $task \\
		-num_threads $threads \\
		-query $query \\
		-db $db \\
		-evalue $evalue \\
		-culling_limit $culling \\
		-outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames' \\
		-out ${outdir}/$basename.$task";
	
	## Checking for queries without hits in BLAST homology searches
	if ($verbose){ print "Checking for sequences in $query with no hits using $task against $db...\n"; }
	open BLAST, "<", "${outdir}/$basename.$task" or die "Can't read file $basename.$task: $!\n";
	my %db;
	while (my $line = <BLAST>){
		my @array = split("\t", $line);
		$db{$array[0]} = $array[1];
	}

	open FASTA, "<", "$query" or die "Can't read file $query: $!\n";
	open NOHIT, ">", "${outdir}/$basename.$task.nohit" or die "Can't write to file $basename.$task.nohit: $!\n";
	while (my $line = <FASTA>){
		chomp $line;
		if ($line =~ /^>(\S+)/){
			if (exists $db{$1}){next;}
			else {print NOHIT "$1\n";}
		}
	}
}

