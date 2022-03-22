#!/usr/bin/perl
## Pombert Lab 2022
my $name = "get_organism_statistics.pl";
my $version = "0.5a";
my $updated = "2022-03-22";

use warnings;
use strict;
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);
use File::Basename;

my $usage = << "EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	The purpose of this script is to take an NCBI generated list of organisms
		and download their corresponding assembly files

USAGE		${name} \\

OPTIONS
-s (--sample)	File output from run_Taxonomized.pl
-d (--db)	Directory of databases created by create_database.pl
-n (--names)	NCBI names.dmp file
-o (--outdir)	Output directory [Default=Normalized]

EXIT

die("\n$usage\n") unless(@ARGV);

my $sample;
my $db;
my $names_file;
my $outdir = "Normalized";

GetOptions(
	's|sample=s' => \$sample,
	'd|db=s' => \$db,
	'n|names_file=s' => \$names_file,
	'o|output=s' => \$outdir,
);

my @preferred_ranks = ( "species", "genus", "family", "order", "class", "phylum", "superkingdom");
my %preferred_ranks = ( "species" => 0,
						"genus" => 1,
						"family" => 2,
						"order" => 3,
						"class" => 4,
						"phylum" => 5,
						"superkingdom" => 6)
;

unless(-d $outdir){
	make_path("$outdir/Figure_files",{mode => 0755});
}
unless(-d "$outdir/Figure_files"){
	make_path("$outdir/Figure_files",{mode => 0755});
}

#######################################################################################################################
## Obtain information from provided sample
#######################################################################################################################

open SAMPLE, "<", $sample or die("Unable to open file $sample: $!\n");

my $rank;
my $genes;
my %sample;
while(my $line = <SAMPLE>){
	chomp($line);
	my @data = split("\t",$line);
	unless($rank){
		$rank = $data[0];
		($genes) = $data[3] =~ /\(total = (\d+)\)/;
	}
	else{
		my $tax_id = $data[1];
		my $gene_count = $data[2];
		my ($percentage) = $data[3] =~ /(\S+)%/;
		$sample{$tax_id}[0] = $gene_count;
		$sample{$tax_id}[1] = $percentage;
	}
}

close SAMPLE;

#######################################################################################################################
## Creating taxon links from database file
#######################################################################################################################

my %taxon_links;
open TAXON, "<", "$db/taxon_links.tsv" or die("Unable to open file $db/taxon_links.tsv: $!\n");
while(my $line = <TAXON>){
	chomp($line);
	my ($taxid, @data) = split("\t",$line);
	$taxon_links{$taxid} = [$taxid,@data];
}

#######################################################################################################################
## Get rRNA information from database files
#######################################################################################################################

my $rank_pos = $preferred_ranks{$rank};

## Reorganize taxon links based on input file provided
foreach my $taxid (keys(%taxon_links)){
	if(int($rank_pos) > 0){
		for (my $i = 0; $i < int($rank_pos); $i++){
			shift(@{$taxon_links{$taxid}});
		}
		@{$taxon_links{$taxon_links{$taxid}[0]}} = @{$taxon_links{$taxid}};
		undef($taxon_links{$taxid});
	}
}

my @missing_taxons;
foreach my $taxid (sort(keys(%sample))){
	push(@missing_taxons,$taxid);
}

my %normalized;
my $normalized_composition;
RANK:while(0==0){
	## Stop looking for rRNA data if no more db files to look in
	if($rank_pos < 0){
		last RANK;
	}
	my @temp_missing;
	my %rRNA_info;

	## Get the current rank based off the rank position
	my $rank_file = $preferred_ranks[$rank_pos];
	open DB_FILE, "<", "$db/$rank_file.db" or die("Unable to open $db/$rank_file.db: $!\n");

	## Add rRNA data from database into RAM
	while(my $line = <DB_FILE>){
		chomp($line);
		unless($line =~ /^Organism/){
			my ($name,$taxon,$rRNA_data) = split("\t",$line);
			@{$rRNA_info{$taxon}} = split(";",$rRNA_data);
		}
	}

	my $prev_rank_pos = $rank_pos;

	## Look for rRNA data in the loaded database file
	while(my $taxid = shift(@missing_taxons)){

		my $rank_ID = $taxon_links{$taxid}[0];

		unless($rank_ID){
			print("  [W]  $taxid is not found in NCBI's node.dmp!\n");
			next RANK;
		}

		## If the information is found, get the statistical data
		if($rRNA_info{$rank_ID}){
			
			## Obtain the rRNA data from the rank file using the corresponding taxID related to that rank
			my @counts = @{$rRNA_info{$rank_ID}};
			@counts = sort({$a <=> $b}@counts);
			my $mode = int(mode(@counts));

			## Get non-normalized data
			my $gene_count = $sample{$taxid}[0];
			my $old_percentage = $sample{$taxid}[1];

			## Add the number of normalized organisms to total count
			$normalized_composition += $gene_count/$mode;
			
			$normalized{$taxid}[1] = $rank_file;
			@{$normalized{$taxid}[2]} = @counts;
			$normalized{$taxid}[3] = $gene_count;
			$normalized{$taxid}[4] = $old_percentage;
			$normalized{$taxid}[5] = $gene_count/$mode;

		}
		## If the information is not found, add taxid to the missing list
		else{
			## Get taxonomic information from the loaded links
			push(@temp_missing,$taxid);
		}
		## Shift the taxon information over
		shift(@{$taxon_links{$taxid}});
		$taxon_links{$taxid} = \@{$taxon_links{$taxid}};
	}
	close DB_FILE;
	## Reassign missing taxons
	@missing_taxons = @temp_missing;
	## If there are any missing taxons, open ascending database file and attempt to find rRNA data
	if(scalar(@missing_taxons) > 1 && $rank_pos < scalar(@preferred_ranks) - 1){
		$rank_pos++;
		goto RANK;
	}
	else{
		last RANK;
	}
}

#######################################################################################################################
## Acquire names of organisms from their taxid
#######################################################################################################################

open NAMES, "<", $names_file or die "Unable to open $names_file: $!\n";

while (my $line = <NAMES>){
	chomp($line);
	if ($line =~ /scientific name/){
		my ($taxid,$separater,$org_name,@other_stuff) = split("\t",$line);
		if ($normalized{$taxid}){
			$normalized{$taxid}[0] = $org_name;
		}
	}
}

close NAMES;

#######################################################################################################################
## Print out results
#######################################################################################################################

my ($file_handle,undef) = fileparse($sample);
$file_handle =~ s/\./\_/g;

open RESULTS, ">", "$outdir/${file_handle}_Normalized_Microbiome_Composition.tsv" or die "Unable to open $outdir/${file_handle}_Normalized_Microbiome_Composition.tsv: $!\n";
print RESULTS ("###Organism Name\tTaxID\tTaxo Level\tNon-normalized % of sample\tNormalized % of sample\tDelta\n");
open LOG, ">", "$outdir/Figure_files/${file_handle}_Normalized_Microbiome_Count.log" or die "Unable to open $outdir/${file_handle}_Normalized_Microbiome_Count.log: $!\n";
print LOG ("###Organism Name\tTaxID\tGene count\trRNA counts\n");

foreach my $taxid (sort({$normalized{$b}[5] <=> $normalized{$a}[5]}(keys(%normalized)))){
	
	my $org_name = $normalized{$taxid}[0];
	my $tax_level = $normalized{$taxid}[1];
	my @counts = @{$normalized{$taxid}[2]};
	my $gene_count = $normalized{$taxid}[3];
	my $old_percentage = $normalized{$taxid}[4];
	my $normalized_count = $normalized{$taxid}[5];

	my @normalized_count;

	foreach my $count (@counts){
		push(@normalized_count,$count);
	}

	my $new_percentage = sprintf("%.2f",($normalized_count/$normalized_composition)*100);
	my $delta = sprintf("%.2f",$new_percentage - $old_percentage);

	print RESULTS ($org_name."\t".$taxid."\t".$tax_level."\t".$old_percentage."\t".$new_percentage."\t".$delta."\n");
	print LOG ($org_name."\t".$taxid."\t".$gene_count."\t".join(";",@normalized_count)."\n");
}

close RESULTS;
close LOG;

#######################################################################################################################
## Subroutines
#######################################################################################################################

sub mean {
	my @data = @_;
	my $count = 0;
	foreach my $datum (@data){
		$count += $datum;
	}
	return sprintf("%.2f",$count/scalar(@data));
}

sub median {
	my @data = @_;
	my $median;
	if(scalar(@data)%2 == 0){
		$median = ($data[(scalar(@data)/2)-1] + $data[(scalar(@data)/2)])/2;
	}
	else{
		$median = $data[int(scalar(@data)/2)];
	}
	return sprintf("%.2f",$median);
}

sub mode {
	my @data = @_;
	my %rRNA;
	foreach my $count (@data){
		unless($rRNA{$count}){
			$rRNA{$count} = 1;
		}
		else{
			$rRNA{$count} += 1;
		}
	}
	my ($top,@rest) = sort({$rRNA{$b} <=> $rRNA{$a}}(keys(%rRNA)));
	return $top;
}