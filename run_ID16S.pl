#!/usr/bin/perl
## Pombert Lab 2022
my $name = "run_ID16S.pl";
my $version = "0.2b";
my $updated = "2022-04-01";

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use File::Path qw(make_path);

my $usage = <<"EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Master script that runs the ID16S pipeline on FASTA/FASTQ files

USAGE		${name} \\
		  -fq *.fastq.gz \\
		  -headcrop 50

GENERAL OPTIONS
-o (--outdir)		Output directory [Default = ./ID16S]
-fa (--fasta)		FASTA files to run
-fq (--fastq)		FASTQ files to convert then run
-hd (--headcrop)	Remove the first X nucleotides from 5' end of FASTQ sequences ## Useful for Nanopore data
-m (--min_length)	Minimum read length to keep from FASTQ files [Default: 1000]

ID16S OPTIONS
-d (--db)		Path to 16IDS_DB download [Default = \$ID16S_DB]

BLAST OPTIONS
-k (--tasks)		megablast, dc-megablast, blastn [default = megablast]
-t (--threads)		CPUs to use [default = 10]
-cu (--culling)		Culling limit [default = 10]
-h (--hits)		Number of hits to return [Default = 1]
-pe (--p_evalue)	Preliminary e-value cutoff for BLAST results [Default = 1e-05]

OUTPUT OPTIONS
-r (--ranks)		Output files by taxonomic ranks [Default: species genus family order class]
-fe (--f_evalue)	Final e-value cutoff for BLAST results [Default = 1e-75]
-co (--concat)		Concatenate all results into a single file [Default: off]
EXIT

die("\n$usage\n") unless(@ARGV);

###################################################################################################
## Command line options
###################################################################################################

## GENERAL
my $outdir = './ID16S';
my @fastq;
my @fasta;
my $headcrop;
my $min_length = 1000;

## ID16S SETTINGS
my $db;

## BLAST
my $task = "megablast";
my $threads = 10;
my $culling = 10;
my $hits = 1;
my $p_evalue = "1e-05";

## OUTPUT
my @ranks = ("species","genus","family","order","class");
my $f_evalue = "1e-75";
my $concat;

GetOptions(
	# GENERAL
	'fq|fastq=s@{0,}' => \@fastq,
	'fa|fasta=s@{0,}' => \@fasta,
	'hd|headcrop=i' => \$headcrop,
	'm|min_length=i' => \$min_length,
	# ID16S SETTINGS
	'o|outdir=s' => \$outdir,
	'd|db=s' => \$db,
	# BLAST
	'k|tasks=s' => \$task,
	't|threads=s' => \$threads,
	'cu|culling=s' => \$culling,
	'h|hits=s' => \$hits,
	'pe|p_evalue=s' => \$p_evalue,
	# OUTPUT
	'r|ranks=s@{0,}' => \@ranks,
	'fe|f_evalue=s' => \$f_evalue,
	'co|concat=s' => \$concat,
);

my $fasta_dir = "$outdir/FASTA";
my $blast_dir = "$outdir/BLAST";
my $nonnormal_dir = "$outdir/NonNormalized";
my $normal_dir = "$outdir/Normalized";

my @output_directories = ($fasta_dir,$blast_dir,$nonnormal_dir,$normal_dir);

my ($run_ID16S,$ID16S_dir) = fileparse($0);

if (exists $ENV{"ID16S_DB"}){
	$db = $ENV{"ID16S_DB"};
}
else {
	unless ($db){
		print STDERR ("\$ID16S_DB is not set as an enviroment variable and -d (--db) was not provided.\n");
		print("To use run_ID16S.pl, please add \$ID16S_DB to the enviroment or specify path with -d (--db)\n");
		exit;
	}
}

if (exists $ENV{"ID16S_HOME"}){
	$outdir = $ENV{"ID16S_HOME"};
}
else {
	unless ($outdir){
		print STDERR ("\$ID16S_HOME is not set as an enviroment variable and -o (--outdir) was not provided.\n");
		print ("To use run_ID16S.pl, please add \$ID16S_HOME to the enviroment or specify path with -o (--outdir)\n");
		exit;
	}
}

foreach my $dirs (@output_directories){
	unless (-d $dirs){
		make_path($dirs,{mode=>0755});
	}
}

###################################################################################################
## run fastq2fasta.pl
###################################################################################################

if (@fasta){
	foreach my $file (@fasta){
		system ("cp $file $fasta_dir/$file");
	}
}

if (@fastq){
	print ("\nConverting FASTQ to FASTA with fastq2fasta.pl\n");

	my $crop_5end = '';
	if ($headcrop){
		$crop_5end = "--headcrop $headcrop";
	}

	system ("$ID16S_dir/Core_scripts/fastq2fasta.pl \\
			  --fastq @fastq \\
			  --outdir $fasta_dir \\
			  --min_length $min_length \\
			  $headcrop
	");
}
else {
	die ("FASTQ or FASTA files are required by run_ID16S.pl\n");
}


###################################################################################################
## run megablast.pl
###################################################################################################

print ("\nRunning BLAST search on FASTA files with megablast.pl\n");
system ("$ID16S_dir/Core_scripts/megablast.pl \\
		  --task $task \\
		  --query $fasta_dir/*.fasta \\
		  --evalue $p_evalue \\
		  --culling $culling \\
		  --threads $threads \\
		  --outdir $blast_dir
");

###################################################################################################
## run taxid_dist.pl
###################################################################################################

print ("\nAcquiring TaxIDs for BLAST hits\n");
system ("$ID16S_dir/Core_scripts/taxid_dist.pl \\
		  --blast $outdir/BLAST/*.$task \\
		  --nodes $db/TaxDump/nodes.dmp \\
		  --names $db/TaxDump/names.dmp \\
		  --evalue $f_evalue \\
		  --hits $hits \\
		  --ranks @ranks \\
		  --outdir $nonnormal_dir
");

###################################################################################################
## get_organism_statistics.pl
###################################################################################################

opendir (NNORM,$nonnormal_dir) or die("Unable to open $nonnormal_dir: $!\n");

foreach my $file (readdir(NNORM)){
	unless (-d $file){
		system ("$ID16S_dir/Normalization_scripts/get_organism_statistics.pl \\
				  --sample $nonnormal_dir/$file \\
				  --db $db/Normalization_DB \\
				  --name $db/TaxDump/names.dmp \\
				  --output $normal_dir;
		");
	}
}
