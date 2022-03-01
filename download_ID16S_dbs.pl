#!/usr/bin/perl
## Pombert Lab 2022
my $name = "download_ID16S_dbs.pl";
my $version = "0.1a";
my $updated = "2022-02-24";

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use File::Path qw(make_path);

my $usage = <<"EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	This script downloads the required databases from NCBI, with the option of creating a 
		new normalization database.

USAGE		${name} \\
			  -d \\
			  -o ID16S_DB 

OPTIONS
-d (--download)	Download NCBI databases
-c (--create)	Download genomes for 'Bacteria' and create a new normalization database [Default: Off]
-o (--outdir)	Output directory [Default = \$ID16S_DB]
EXIT

die("\n$usage\n") unless(@ARGV);

my $download;
my $make;
my $outdir;

GetOptions(
	'd|download' => \$download,
	'c|create' => \$make,
	'o|outdir=s' => \$outdir,
);

unless($download){
	die("\n$usage\n");
}

my ($download_script,$ID16S_dir) = fileparse($0);

unless($outdir){
	if($ENV{"ID16S_DB"}){
		$outdir = $ENV{"ID16S_DB"};
	}
	else{
		print STDERR ("\$ID16S_DB is not set as an enviroment variable and -o (--outdir) was not provided.\n");
		print("To use $name, please add \$ID16S_DB to the enviroment or specify path with -o (--outdir)\n");
		exit;
	}
}

my $NCBI_16S_dir = "$outdir/NCBI_16S";
my $TaxDB_dir = "$outdir/TaxDB";
my $TaxDump_dir = "$outdir/TaxDump";
my $genomes_dir = "$outdir/NCBI_GBFF_Files";
my $normal_dir = "$outdir/Normalization_DB";

my @dirs = ($NCBI_16S_dir,$TaxDB_dir,$TaxDump_dir,$genomes_dir,$normal_dir);

foreach my $dir (@dirs){
	unless(-d $dir){
		make_path($dir,{mode => 0755}) or die("Unable to create directory $dir: $!\n");
	}
}

###################################################################################################
## Downloading NCBI 16S Database
###################################################################################################
system "wget ftp://ftp.ncbi.nih.gov/blast/db/16S_ribosomal_RNA.tar.gz -O $NCBI_16S_dir/16S_ribosomal_RNA.tar.gz";
system "tar -zxvf $NCBI_16S_dir/16S_ribosomal_RNA.tar.gz --directory $NCBI_16S_dir";
system "rm $NCBI_16S_dir/16S_ribosomal_RNA.tar.gz";

###################################################################################################
## Downloading NCBI Taxonomy Database
###################################################################################################

system "wget ftp://ftp.ncbi.nih.gov/blast/db/taxdb.tar.gz -O $TaxDB_dir/taxdb.tar.gz";
system "tar -zxvf $TaxDB_dir/taxdb.tar.gz --directory $TaxDB_dir";
system "rm $TaxDB_dir/taxdb.tar.gz";

###################################################################################################
## Downloading NCBI Taxonomy dump Files
###################################################################################################

system "wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz -O $TaxDump_dir/taxdump.tar.gz";
system "tar -zxvf $TaxDump_dir/taxdump.tar.gz --directory $TaxDump_dir";
system "rm $TaxDump_dir/taxdump.tar.gz";

###################################################################################################
## Downloading 'Bacteria' GBFF species
###################################################################################################
CHECK:
if(defined $make){
	while(0==0){
		ASK:
		print("\nRecreation of normalization database will require a download of ");
		print(".gbff files of all 'Bacteria' in NCBI. This is a sizeable download ");
		print("(~250Gb decompressed) and may take a while to download. ");
		print("Are you sure you would like to download? (y/n)\n\tSelection: ");
		chomp(my $response = lc(<STDIN>));
		if($response eq "y"){
			goto VERIFIED;
		}
		elsif($response eq "n"){
			undef $make;
			goto CHECK;
		}
		else{
			print("$response is an invalid selection.\n");
			goto ASK;
		}
		
	}
	VERIFIED:
	print "\nDownloading datasets program from NCBI\n";
	system "curl https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/LATEST/linux-amd64/datasets -o $genomes_dir/datasets";
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
	system "cp $ID16S_dir/Normalization_scripts/Prebuilt_Normalization_DB/*.* $normal_dir/";
}

