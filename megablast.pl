#!/usr/bin/perl
## Pombert Lab, IIT 2018
## Requires BLAST 2.2.28+ or later and the NCBI taxonomony database (ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz)
## The BLASTDB variable must be set in the environmental variables: export BLASTDB=/path/to/NCBI/TaxDB

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my $usage = "
USAGE = perl megablastn.pl [options]

EXAMPLE: megablast.pl -k megablast -q Examples/sample_1.fasta -d NCBI_16S/16SMicrobial -e 1e-05 -c 10 -t 10

OPTIONS:
-k (--task)		megablast, dc-megablast, blastn [default = megablast]
-d (--db)		NCBI 16S Microbial Database to query [default = XXX]
-t (--threads)	CPUs to use [default = 10]
-e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
-c (--culling)	culling limit [default = 10]
-q (--query)		fasta file(s) to be queried
";

die "$usage\n" unless@ARGV;

## Defining options
my $task = 'megablast';
my $db = 'nr';
my $threads = '2';
my $evalue = '1e-05';
my $culling = '1';
my @query = ();

GetOptions(
    'k|task=s' => \$task,
	'd|db=s' => \$db,
	't|threads=i' => \$threads,
	'e|evalue=s' => \$evalue,
	'c|culling=i' => \$culling,
	'q|query=s@{1,}' => \@query,
);

## Running BLAST
while (my $tmp = shift@query){
	system "echo Running $task on $tmp...";
	system "blastn -task $task -num_threads $threads -query $tmp -db $db -evalue $evalue -culling_limit $culling -outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames' -out $tmp.$task";
}

