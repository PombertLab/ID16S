#!/usr/bin/perl
## Pombert Lab 2022
my $name = "download_ID16S_dbs.pl";
my $version = "0.1";
my $updated = "2022-02-21";

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

USAGE

OPTIONS
-m (--make)		Download NCBI genomes for 'Bacteria' and make new normalization database [Default: Off]
-o (--outdir)	Output directory [Default = ID16S_DB]
EXIT

die("\n$usage\n") unless(@ARGV);

my $make;
my $outdir = "ID16S_DB";

GetOptions(
	'-m|--make' => \$make,
	'-o|--outdir=s' => \$outdir,
);

my ($download_script,$ID16S_dir) = fileparse($0);

my $NCBI_16S_dir = "$outdir/NCBI_16S";
my $TaxDB_dir = "$outdir/TaxDB";
my $TaxDump_dir = "$outdir/TaxDump";
my $RNA_16S_dir = "$outdir/16S_ribosomal_RNA";
my $genomes_dir = "$outdir/NCBI_GBFF_Files";
my $normal_dir = "$outdir/Normalization_DB";

unless(-d $outdir){
	make_path($NCBI_16S_dir,{mode => 0755}) or die("Unable to make directory $NCBI_16S_dir: $!\n");
	make_path($TaxDB_dir,{mode => 0755}) or die("Unable to make directory $TaxDB_dir: $!\n");
	make_path($TaxDump_dir,{mode => 0755}) or die("Unable to make directory $TaxDump_dir: $!\n");
	make_path($RNA_16S_dir,{mode => 0755}) or die("Unable to make directory $RNA_16S_dir: $!\n");
	if($make){
		make_path($genomes_dir,{mode => 0755}) or die("Unable to make directory $genomes_dir: $!\n");
	}
	make_path($normal_dir,{mode => 0755}) or die("Unable to make directory $normal_dir: $!\n");
}

###################################################################################################
## Downloading NCBI 16S Database
###################################################################################################

system "wget ftp://ftp.ncbi.nih.gov/blast/db/16S_ribosomal_RNA.tar.gz -O $NCBI_16S_dir";
system "tar -zxvf $NCBI_16S_dir/16S_ribosomal_RNA.tar.gz --directory $NCBI_16S_dir";
system "rm $NCBI_16S_dir/16S_ribosomal_RNA.tar.gz";

###################################################################################################
## Downloading NCBI Taxonomy Database
###################################################################################################

system "wget ftp://ftp.ncbi.nih.gov/blast/db/taxdb.tar.gz -O $TaxDB_dir";
system "tar -zxvf $TaxDB_dir/taxdb.tar.gz --directory $TaxDB_dir";
system "rm $TaxDB_dir/taxdb.tar.gz";

###################################################################################################
## Downloading NCBI Taxonomy dump Files
###################################################################################################

system "wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz -O $TaxDump_dir";
system "tar -zxvf $TaxDump_dir/taxdump.tar.gz --directory $TaxDump_dir";
system "rm $TaxDump_dir/taxdump.tar.gz";

###################################################################################################
## Downloading 'Bacteria' GBFF species
###################################################################################################
CHECK:
if($make){
	while(0==0){
		print("\nRecreation of normalization database will require a download of ");
		print(".gbff files of all 'Bacteria' in NCBI. This is a sizeable download ");
		print("(~250Gb decompressed) and may take a while to download. ")
	}
	VERIFIED:
	print "\nDownloading datasets program from NCBI\n";
	system "curl https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/LATEST/linux-amd64/datasets -o $outdir/datasets";
	system "chmod +x $outdir/datasets";

	unless(-d "$genomes_dir/ncbi_datasets.zip"){
		system "$outdir/datasets \\
				  download \\
				  genome \\
				  taxon 'bacteria' \\
				  --exclude-genomic-cds \\
				  --exclude-gff3 \\
				  --exclude-protein \\
				  --exclude-rna \\
				  --exclude-seq \\
				  --include-gbff \\
				  --assembly-level complete_genome \\
				  --assembly-source refseq \\
				  --annotated \\
				  --filename $genomes_dir/ncbi_dataset.zip
		";
	}

	system "unzip $genomes_dir/ncbi_dataset.zip";
	
	opendir(GENOMES,"$genomes_dir/ncbi_dataset/data") or die("Unable to open directory $genomes_dir/ncbi_dataset/data: $!");
	while (my $dir = readdir(GENOMES)){
		print ("$dir\n");
		# if($dir =~ //)
		# print "mv $genomes_dir/ncbi_dataset/data/$dir/genomic.gbff $genomes_dir/$1.gbff\n";
		# print "gzip $genomes_dir/$1.gbff\n";
	}
	# system "rm -r $genomes_dir/ncbi_dataset";
	closedir(GENOMES);
}
else{
	system "cp $ID16S_dir/PreBuilt_Normalization_DB/*.* $normal_dir/";
}

