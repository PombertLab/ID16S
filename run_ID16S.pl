#!/usr/bin/perl
## Pombert Lab 2022
my $name = "run_ID16S.pl";
my $version = "0.2";
my $updated = "2022-03-22";

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use File::Path qw(make_path);


my $usage = <<"EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	

USAGE		${name} \\

OPTIONS
-fa (--fasta)	FASTA files to run
-fq (--fastq)	FASTQ files to convert then run

ADVANCED
-o (--outdir)	Output directory [Default = \$ID16S_HOME]
-d (--db)	Path to 16IDS_DB download [Default = \$ID16S_DB]
-co (--concat)		Concatenate all results into a single file [Default: off]
-t (--threads)		CPUs to use [default = 10]
-cu (--culling)		Culling limit [default = 10]
-k (--tasks)		megablast, dc-megablast, blastn [default = megablast]
-pe (--p_evalue)	Preliminary e-value cutoff for BLAST results [Default = 1e-05]
-h (--hits)		Number of hits to return [Default = 1]
-fe (--f_evalue)	Final e-value cutoff for BLAST results [Default = 1e-75]
-r (--ranks)		Output files by taxonomic ranks [Default: species genus family order class]
EXIT

die("\n$usage\n") unless(@ARGV);

my @fastq;
my @fasta;
my $concat;
my $outdir;
my $db;
my $threads = 10;
my $culling = 10;
my $task = "megablast";
my $p_evalue = "1e-05";
my $hits = 1;
my $f_evalue = "1e-75";
my @ranks = ("species","genus","family","order","class");

GetOptions(
	'fq|fastq=s{0,}' => \@fastq,
	'fa|fasta=s{0,}' => \@fasta,
	'co|concat=s' => \$concat,
	'o|outdir=s' => \$outdir,
	'd|db=s' => \$db,
	'cu|culling=s' => \$culling,
	't|threads=s' => \$threads,
	'pe|p_evalue=s' => \$p_evalue,
	'h|hits=s' => \$hits,
	'fe|f_evalue=s' => \$f_evalue,
	'k|tasks=s' => \$task,
	'r|ranks=s{0,}' => \@ranks,
);

my $fasta_dir = "$outdir/FASTA";
my $blast_dir = "$outdir/BLAST";
my $nonnormal_dir = "$outdir/NonNormalized";
my $normal_dir = "$outdir/Normalized";

my @output_directories = ($fasta_dir,$blast_dir,$nonnormal_dir,$normal_dir);

my ($run_ID16S,$ID16S_dir) = fileparse($0);

if(exists $ENV{"ID16S_DB"}){
	$db = $ENV{"ID16S_DB"};
}
else{
	unless($db){
		print STDERR ("\$ID16S_DB is not set as an enviroment variable and -d (--db) was not provided.\n");
		print("To use run_ID16S.pl, please add \$ID16S_DB to the enviroment or specify path with -d (--db)\n");
		exit;
	}
}

if(exists $ENV{"ID16S_HOME"}){
	$outdir = $ENV{"ID16S_HOME"};
}
else{
	unless($outdir){
		print STDERR ("\$ID16S_HOME is not set as an enviroment variable and -o (--outdir) was not provided.\n");
		print ("To use run_ID16S.pl, please add \$ID16S_HOME to the enviroment or specify path with -o (--outdir)\n");
		exit;
	}
}

foreach my $dirs (@output_directories){
	unless(-d $dirs){
		make_path($dirs,{mode=>0755});
	}
}

###################################################################################################
## run fastq2fasta
###################################################################################################

# COMMAND	fastq2fasta.pl \\
# 			  -f *.fastq \\
# 			  -o FASTA \\
# 			  -v

# -f (--fastq)	FASTQ files to convert
# -o (--outdir)	Output directory [Default: ./]
# -v (--verbose)	Adds verbosity

if(@fasta){
	foreach my $file (@fasta){
		system("cp $file $fasta_dir/$file");
	}
}

if(@fastq){
	print("\nConverting FASTQ to FASTA with fastq2fasta.pl\n");
	system("$ID16S_dir/Core_scripts/fastq2fasta.pl \\
			  --fastq @fastq \\
			  --outdir $fasta_dir
	");
}
else{
	die("FASTQ or FASTA files are required by run_ID16S.pl\n");
}


###################################################################################################
## run megablast
###################################################################################################

# USAGE		megablast.pl \\
# 			  -k megablast \\
# 			  -q Examples/sample_1.fasta \\
# 			  -d NCBI_16S/16S_ribosomal_RNA \\
# 			  -e 1e-05 \\
# 			  -c 10 \\
# 			  -t 10 \\
# 			  -o MEGABLAST \\
# 			  -v

# OPTIONS:
# -k (--task)	megablast, dc-megablast, blastn [default = megablast]
# -q (--query)	fasta file(s) to be queried
# -d (--db)	NCBI nucleotide database to query [default = 16S_ribosomal_RNA]
# -e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
# -c (--culling)	culling limit [default = 10]
# -t (--threads)	CPUs to use [default = 10]
# -o (--outdir)	Output directory [Default: ./]
# -x (--taxids)	Restrict search to taxids from file ## one taxid per line
# -n (--ntaxids)	Exclude from search taxids from file ## one taxid per line
# -v (--verbose)	Adds verbosity

print("\nRunning BLAST search on FASTA files with megablast.pl\n");
system("$ID16S_dir/Core_scripts/megablast.pl \\
		  --task $task \\
		  --query $fasta_dir/*.fasta \\
		  --evalue $p_evalue \\
		  --culling $culling \\
		  --threads $threads \\
		  --outdir $blast_dir
");

###################################################################################################
## run taxid_dist
###################################################################################################

# COMMAND		taxid_dist.pl \\
#				  -n TaxDumps/nodes.dmp \\
#				  -a TaxDumps/names.dmp \\
#				  -b MEGABLAST/*.megablast \\
#				  -e 1e-75 \\
#				  -h 1 \\
#				  -o output_dir \\
#				  -r species genus family order class phylum \\
#				  -v

# OPTIONS:
# -n (--nodes)	NCBI nodes.dmp file 
# -a (--names)	NCBI names.dmp
# -b (--blast)	NCBI blast output file(s) in outfmt 6 format
# -e (--evalue)	evalue cutoff [Default: 1e-75]
# -h (--hits)	Number of BLAST hits to keep; top N hits [Default: 1]
# -o (--outdir)	Output directory [Default: ./]
# -r (--ranks)	Output files by taxonomic ranks [Default: species genus family order class]
# 		# Possible taxonomic rank options are:
# 		# subspecies strain species genus family order class phylum superkingdom 'no rank'
# -v (--verbose)	Adds verbosity

print("\nAcquiring TaxIDs for BLAST hits\n");
system("$ID16S_dir/Core_scripts/taxid_dist.pl \\
		  --blast $outdir/BLAST/*.$task \\
		  --nodes $db/TaxDump/nodes.dmp \\
		  --names $db/TaxDump/names.dmp \\
		  --evalue $f_evalue \\
		  --hits $hits \\
		  --ranks @ranks \\
		  --outdir $nonnormal_dir
");

###################################################################################################
## get_organism_statistics
###################################################################################################

# USAGE		get_organism_statistics.pl \
#			  -s Paul/SUMMARY/bc04_16S.fasta.megablast.genus \
#			  -d ID16S/Complete-Assemblies_rRNA_16S_DBs/ \
#			  -n ID16S/names.dmp \
#			  -o .tsv

# OPTIONS
# -s (--sample)	File output from run_Taxonomized.pl
# -d (--db)		Directory of databases created by create_database.pl
# -n (--names)	NCBI's names.dmp file
# -o (--output)	Output filename [Default = Normalized_Microbiome_Composition.tsv]

opendir(NNORM,$nonnormal_dir) or die("Unable to open $nonnormal_dir: $!\n");

foreach my $file (readdir(NNORM)){
	unless(-d $file){
		system("$ID16S_dir/Normalization_scripts/get_organism_statistics.pl \\
				  --sample $nonnormal_dir/$file \\
				  --db $db/Normalization_DB \\
				  --name $db/TaxDump/names.dmp \\
				  --output $normal_dir;
		");
	}
}
