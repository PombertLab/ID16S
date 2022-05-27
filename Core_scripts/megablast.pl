#!/usr/bin/perl
## Pombert Lab, IIT 2018
my $name = 'megablast.pl';
my $version = '0.4a';
my $updated = '2022-05-27';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;

my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Performs homology searches using BLASTN and returns results with taxonomic metadata

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
-q (--query)	fasta file(s) to be queried
-d (--db)	NCBI nucleotide database to query [default = 16S_ribosomal_RNA]
-e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
-c (--culling)	culling limit [default = 10]
-t (--threads)	CPUs to use [default = 10]
-o (--outdir)	Output directory [Default: ./]
-x (--taxids)	Restrict search to taxids from file ## one taxid per line
-n (--ntaxids)	Exclude from search taxids from file ## one taxid per line
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$usage\n" unless@ARGV;

## Defining options
my $task = 'megablast';
my @query;
my $db = '16S_ribosomal_RNA';
my $evalue = '1e-05';
my $culling = 10;
my $threads = 10;
my $outdir = './';
my $taxids;
my $ntaxids;
my $verbose;

GetOptions(
    'k|task=s' => \$task,
	'q|query=s@{1,}' => \@query,
	'd|db=s' => \$db,
	'e|evalue=s' => \$evalue,
	'c|culling=i' => \$culling,
	't|threads=i' => \$threads,
	'o|outdir=s' => \$outdir,
	'x|taxids=s' => \$taxids,
	'n|ntaxids=s' => \$ntaxids,
	'v|verbose' => \$verbose
);

## Creating output directory
unless (-d $outdir){
	mkdir ($outdir, 0755) or die "Can't create output directory $outdir: $!\n";
}
if ($verbose){ print "\nBLAST output directory: $outdir\n"; }

## Running BLAST homology searches
while (my $query = shift@query){

	my $basename = fileparse($query);

	## Checking for taxonomic restrictions, if any
	## Useful to query a subset of the NCBI NT database
	my $taxonomic_restrictions = '';
	if ($taxids){
		$taxonomic_restrictions = "-taxidlist $taxids";
	}
	elsif ($ntaxids){
		$taxonomic_restrictions = "-negative_taxidlist $ntaxids";
	}

	## Running BLAST
	if ($verbose){ print "Running $task on $query...\n"; }
	system ("blastn \\
		-task $task \\
		-num_threads $threads \\
		-query $query \\
		-db $db \\
		-evalue $evalue \\
		-culling_limit $culling \\
		$taxonomic_restrictions \\
		-outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames' \\
		-out ${outdir}/$basename.$task") == 0 or checksig();
	
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
			if (exists $db{$1}){ next; }
			else { print NOHIT "$1\n"; }
		}
	}
}

### Subroutine(s)
sub checksig {

	my $exit_code = $?;
	my $modulo = $exit_code % 255;

	print "\nExit code = $exit_code; modulo = $modulo \n";

	if ($modulo == 2) {
		print "\nSIGINT detected: Ctrl+C => exiting...\n";
		exit(2);
	}
	elsif ($modulo == 131) {
		print "\nSIGTERM detected: Ctrl+\\ => exiting...\n";
		exit(131);
	}

}