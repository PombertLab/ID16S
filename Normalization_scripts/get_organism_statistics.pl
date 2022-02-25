#!/usr/bin/perl
## Pombert Lab 2022
my $name = "get_organism_statistics.pl";
my $version = "0.4b";
my $updated = "2022-02-23";

use warnings;
use strict;
use Getopt::Long qw(GetOptions);

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
-o (--output)	Output filename [Default=Normalized_Microbiome_Composition.tsv]

EXIT

die("\n$usage\n") unless(@ARGV);

my $sample;
my $db;
my $names_file;
my $output = "Normalized_Microbiome_Composition.tsv";

GetOptions(
	's|sample=s' => \$sample,
	'd|db=s' => \$db,
	'n|names_file=s' => \$names_file,
	'o|output=s' => \$output,
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
	if($line =~ /^TaxID/){
		next;
	}
	unless($rank){
		$rank = $data[0];
		($genes) = $data[4] =~ /\(total = (\d+)\)/;
	}
	else{
		my $tax_id = $data[1];
		my $gene_count = $data[2];
		my ($percentage) = $data[3] =~ /(\S+)%/;
		$sample{$tax_id}[0] = $gene_count;
		$sample{$tax_id}[1] = $percentage;
	}
}

#######################################################################################################################
## Creating taxon links from database file
#######################################################################################################################

my %taxon_links;
open TAXON, "<", "$db/taxon_links.tsv" or die("Unable to open file $db/taxon_links.tsv: $!\n");
while(my $line = <TAXON>){
	chomp($line);
	my ($species, @data) = split("\t",$line);
	$taxon_links{$species} = [$species,@data];
}

#######################################################################################################################
## Get rRNA information from database files
#######################################################################################################################

my $rank_pos = $preferred_ranks{$rank};

## Reorganize taxon links based on input file provided
foreach my $key (keys(%taxon_links)){
	for (my $i = 0; $i < int($rank_pos); $i++){
		shift(@{$taxon_links{$key}});
	}
	$taxon_links{$taxon_links{$key}[0]} = \@{$taxon_links{$key}};
	undef($taxon_links{$key});
}

my @missing_taxons;
foreach my $key (sort(keys(%sample))){
	push(@missing_taxons,$key);
}

my %normalized;
my $normalized_number_of_orgs = 0;
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
		my ($taxon,@rRNA_data) = split("\t",$line);
		$rRNA_info{$taxon} = \@rRNA_data; 
	}

	my $prev_rank_pos = $rank_pos;

	## Look for rRNA data in the loaded database file
	while(my $key = shift(@missing_taxons)){

		my $rank_ID = $taxon_links{$key}[0];

		## If the information is found, get the statistical data
		if($rRNA_info{$rank_ID}){
			## Obtain the rRNA data from the rank file using the corresponding taxID related to that rank
			my ($samples,$min,$max,$mean,$median,$mode,$std) = @{$rRNA_info{$rank_ID}};
			## Get the number of rRNA gene copies for the sample organism
			my $copies = $sample{$key}[0];
			## Normalize the number of organisms according to their rRNA copies
			$normalized{$key}[1] = $rank_file;
			$normalized{$key}[2] = ceil($copies/$max);
			$normalized{$key}[3] = ceil($copies/$median);
			$normalized_number_of_orgs += $normalized{$key}[3];
			$normalized{$key}[4] = ceil($copies/$min);
		}
		## If the information is not found, add key to the missing list
		else{
			## Get taxonomic information from the loaded links
			push(@temp_missing,$key);
		}
		## Shift the taxon information over
		shift(@{$taxon_links{$key}});
		$taxon_links{$key} = \@{$taxon_links{$key}};
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

close SAMPLE;

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

open RESULTS, ">", $output or die "Unable to open $output: $!\n";
print RESULTS ("###Organism Name\tTaxID\tTaxo Level\tMedian # of Organisms\tMin # of Organisms\tMax # of Organisms\tPrevious Percentage of Sample\tPercentage of Sample\tDelta\n");

foreach my $key ( sort {$normalized{$b}[3] <=> $normalized{$a}[3]} keys %normalized){
	my $org_name = $normalized{$key}[0];
	my $taxo_level = $normalized{$key}[1];
	my $min = $normalized{$key}[2];
	my $avg = $normalized{$key}[3];
	my $max = $normalized{$key}[4];
	my $old_percentage = $sample{$key}[1];
	my $new_percentage = $avg/$normalized_number_of_orgs*100;
	my $percent = sprintf("%4.2f",$new_percentage);
	my $diff = diff($new_percentage,$old_percentage);
	print RESULTS ("$org_name\t$key\t$taxo_level\t$avg\t$min\t$max\t$old_percentage\t$percent%\t$diff\n");
}

close RESULTS;

#######################################################################################################################
## Subroutines
#######################################################################################################################

## Rounds a number up to the nearest whole number
sub ceil{
	my $number = $_[0];
	my $trunc_number = int($number);
	if ($number - $trunc_number > 0){
		$trunc_number++;
		return $trunc_number;
	}
	else{
		return $trunc_number;
	}
}

## Gets the difference between the old and new composition
sub diff{
	my $new = $_[0];
	my $old = $_[1];
	if ($new > $old){
		my $diff = $new - $old;
		$diff = sprintf("%4.2f",$diff);
		return "+$diff%";
	}
	else{
		my $diff = $old - $new;
		$diff = sprintf("%4.2f",$diff);
		return "-$diff%";
	}
}