#! /usr/bin/perl

use strict; use warnings; use Getopt::Long qw(GetOptions); use File::Path qw(make_path);

my $name = 'download_organism_data.pl';
my $version = '0.2';
my $updated = '2022-02-15';
my $usage = << "EXIT";
NAME		$name
VERSION		$version
UPDATED		$updated
SYNOPSIS	The purpose of this script is to download GeneBank files for bacterial organisms through NCBIs
		'datasets' program, as well as the latest tax_dump, which contains important files.

USAGE		$name \\
		  --outdir NCBI_Databases

OPTIONS
-o (--outdir)	Directory to store GeneBank files

EXIT

die "\n${usage}\n" unless @ARGV;

my $outdir;

GetOptions(
	"o|outdir=s" => \$outdir,
);

unless(-d $outdir){
	make_path("$outdir/taxdump",{mode => 0755});
}

## Download NCBI taxdump files
unless(-f "$outdir/taxdump/new_taxdump.tar.gz" && -d "$outdir/taxdump/new_taxdump"){
	print "\nDownloading TaxDump from NCBI\n";
	system "curl https://ftp.ncbi.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz -o $outdir/taxdump/new_taxdump.tar.gz";
	system "tar -xf $outdir/taxdump/new_taxdump.tar.gz --directory $outdir/taxdump; ";
}
elsif(-f "$outdir/taxdump/new_taxdump.tar.gz"){
	system "tar -xf $outdir/taxdump/new_taxdump.tar.gz --directory $outdir/taxdump";
}

## Check for NCBI datasets program
unless(-f "$outdir/datasets"){
	print "\nDownloading datasets program form NCBI\n";
	system "curl https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/LATEST/linux-amd64/datasets -o $outdir/datasets";
}
system "chmod +x $outdir/datasets";

unless(-d "$outdir/DB"){
	make_path("$outdir/DB",{mode => 0755});
}

unless(-d "$outdir/DB/ncbi_datasets.zip"){
	system "$outdir/datasets \\
			download \\
			genome \\
			taxon bacteria \\
			--exclude-genomic-cds \\
			--exclude-gff3 \\
			--exclude-protein \\
			--exclude-rna \\
			--exclude-seq \\
			--include-gbff \\
			--assembly-level complete_genome \\
			--assembly-source refseq \\
			--annotated \\
			--filename $outdir/DB/ncbi_dataset.zip
	";
}
else{
	system "unzip $outdir/DB/ncbi_dataset.zip";
}


print("\n");