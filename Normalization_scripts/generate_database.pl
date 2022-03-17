#! /usr/bin/perl
##
my $name = 'generate_database.pl';
my $version = '0.5';
my $updated = '2022-03-16';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use PerlIO::gzip;
use File::Path qw(make_path);

my $usage = << "EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	This script creates a database of 16s ribosomal RNA count for a provided
		selection of organisms

COMMAND		${name} \\
		  -d /media/FatCat_1/Databases/NCBI/Complete_Seq_RefSeq/ \\
		  -na ID16S_DB/TaxDump/names.dmp \\
		  -no ID16S_DB/TaxDump/nodes.dmp \\
		  -o ./rRNA_16S_DBs


OPTIONS
-d (--data)	Directory containing organism data
-na (--name)	NCBI taxonomy name.dmp file
-no (--node)	NCBI taxonomy node.dmp file
-o (--out)	Output directory [Default: ./rRNA_16S_DBs]
EXIT

die "\n$usage\n" unless @ARGV;

my $org_dir;
my $node_file;
my $name_file;
my $outdir = "./rRNA_16S_DBs";

GetOptions(
	"d|data=s" => \$org_dir,
	"no|node=s" => \$node_file,
	"na|name=s" => \$name_file,
	"o|out=s" => \$outdir,
);

unless(-d $outdir){
	make_path($outdir,{mode=>0755});
}

my @preferred_ranks = ("superkingdom", "phylum", "class", "order", "family", "genus", "species");

###############################################################################
## Store links between taxid and organism name
###############################################################################

open NAMES, "<", $name_file or die("Unable to open file $name_file");

my %names;
while (my $line = <NAMES>){
	chomp($line);
	my ($taxid,$separater,$org_name,@other_stuff) = split("\t",$line);
	$names{$taxid} = $org_name;
}


###############################################################################
## Create a link between the taxid of the organism and the number of 16S copies
###############################################################################


my %orgs_rna_count;
my $missing_org = 0;
my $total_org = 0;
unless(-f "$outdir/raw_16S_data.dmp"){
	opendir(ORG_DIR,$org_dir) or die("Unable to open $org_dir: $!\n");
	open OUT, ">", "$outdir/raw_16S_data.dmp" or die("Unable to open file $outdir/raw_16S_data.dmp: $!\n");
	OUTER:while (my $org_file = readdir(ORG_DIR)){
		unless(-d $org_file){
			open ORG_FILE, "<:gzip", "$org_dir/$org_file";
			my $rRNA_count = 0;
			my $tax_id;
			my $org_name = '';
			my $header;
			my $feature = '';
			WHILE: while (my $line = <ORG_FILE>){
				chomp($line);
				## If there is a header for rRNA
				if ($line =~ /\s{2,}rRNAs\D+(\d+)/){
					$rRNA_count = $1;
					$header = 1;
				}
				if ($line =~ /\s+\/db_xref="taxon:(\d+)"/){
					$tax_id = $1;
				}
				## If there is no header, parse the full file
				if ($line =~ /^\s{1,5}(gene|rRNA|tRNA|CDS)/){
					$feature = $1;
				}
				if ($feature eq "rRNA"){
					if ($line =~ /\/product="(.+)"*/){
						my $rRNA_type = $1;
						if($rRNA_type =~ /16S/){
							$rRNA_count++;
						}
					}
				}
			}
			if($rRNA_count > 0){
				$orgs_rna_count{$tax_id} = $rRNA_count;
				print OUT $tax_id."\t".$rRNA_count."\n";
			}
			else{
				print("No 16S rRNA found for $org_file with TaxID of $tax_id!\n");
				$missing_org ++;
			}
			$total_org ++;
			close ORG_FILE;
		}
	}
	close ORG_DIR;
	print ("\nrRNA data missing for $missing_org organisms of $total_org organisms\n\n");
	close OUT;
}
else{
	open IN, "<", "$outdir/raw_16S_data.dmp" or die("Unable to open file $outdir/raw_16S_data.dmp: $!\n");
	while(my $line = <IN>){
		chomp($line);
		my ($tax_id,$rRNA_count) = split("\t",$line);
		$orgs_rna_count{$tax_id} = $rRNA_count;
	}
}

###############################################################################
## Create a link between a child and parent in taxonomic tree
###############################################################################

open NODE_FILE, "<", $node_file or die("Unable to open file $node_file: $!\n");
my %linked_nodes;
my %reversed_linked_nodes;
while (my $line = <NODE_FILE>){
	chomp($line);
	my @line_data = split(/\t\|\t/,$line);
	if ($line_data[4] == 0){

		my $child_org_tid = $line_data[0];
		my $parent_org_tid = $line_data[1];
		my $child_rank = $line_data[2];

		$linked_nodes{$child_org_tid}[0] = $parent_org_tid;
		$linked_nodes{$child_org_tid}[1] = $child_rank;

	}
}
close NODE_FILE;

###############################################################################
## Store desirable taxonomic links in a file
###############################################################################

open LINKED, ">", "$outdir/taxon_links.tsv" or die("Unable to write to $outdir/taxon_links.tsv: $!\n");

foreach my $key (keys(%linked_nodes)){
	my %taxons = ( "superkingdom" => undef,
				   "phylum" => undef,
				   "class" => undef,
				   "order" => undef,
				   "family" => undef,
				   "genus" => undef,
				   "species" => undef
	);
	## Check if the key being inspected is linked to the species rank
	if($linked_nodes{$key}[1] eq $preferred_ranks[-1]){
		my $ID = $key;
		my $rank = $linked_nodes{$ID}[1];
		## Iterate through all taxonomic relationships
		while($linked_nodes{$ID}[0]){
			## If the rank is desirable, store it in the link file
			if(desirable_rank($rank)){
				### PRINT THE RANK TO OUTPUT FILE ###
				$taxons{$rank} = $ID;
			}
			## Move to the parent relationship
			$ID = $linked_nodes{$ID}[0];
			$rank = $linked_nodes{$ID}[1];
		}
		foreach my $rank (reverse(@preferred_ranks)){
			if($taxons{$rank}){
				print LINKED ("$taxons{$rank}\t");
			}
			else{
				print LINKED ("N\/A\t");
			}
		}
		print LINKED ("\n");
	}
}

close LINKED;

###############################################################################
## Count the rRNA present at each taxonomic level
###############################################################################

my %rRNA_by_level;
foreach my $org (keys(%orgs_rna_count)){
	my $parent;
	my $parent_rank;
	my $base_org = $org;
	WHILE:while(0==0){

		## Proceed if the organism has a deeper lineage
		## Exit the loop if no deeper lineage found

		unless($linked_nodes{$org}[0]){
			last WHILE;
		}
		elsif($linked_nodes{$linked_nodes{$org}[0]}[0]){
			$parent = $linked_nodes{$org}[0];
			$parent_rank = $linked_nodes{$parent}[1];
			push(@{$rRNA_by_level{$parent_rank}{$parent}},$orgs_rna_count{$base_org});
			$org = $parent;
		}
		else{
			last WHILE;
		}
	}
}

my $header = "Organism Name\tTaxID\t# of rRNA Copies\n";
my %filehandles;
foreach my $rank (@preferred_ranks){
	$filehandles{$rank} = "$outdir/$rank.db";
	open OUT, ">", $filehandles{$rank} or die("Unable to open file $filehandles{$rank}: $!");
	print OUT ($header);
	close OUT;
}

my %printed_taxons;
foreach my $rank (keys(%rRNA_by_level)){
	foreach my $org (keys(%{$rRNA_by_level{$rank}})){
		my $org_name = $names{$org};
		my @rRNA_count = @{$rRNA_by_level{$rank}{$org}};
		unless($printed_taxons{$org}){
			open OUT, ">>", $filehandles{$rank} or die("Unable to open file $filehandles{$rank}: $!");
			print OUT ("$org_name\t$org\t".join(";",@rRNA_count)."\n");
			close OUT;
		}
		$printed_taxons{$org} = 1;
		my $parent;
		my $parent_rank;
		my $base_org = $org;
		while($linked_nodes{$linked_nodes{$org}[0]}[0]){
			$parent = $linked_nodes{$org}[0];
			$parent_rank = $linked_nodes{$parent}[1];
			my $parent_name = $names{$parent};
			my @rRNA_count = @{$rRNA_by_level{$parent_rank}{$parent}};
			unless($printed_taxons{$parent}){
				open OUT, ">>", $filehandles{$parent_rank} or die("Unable to open file $filehandles{$rank}: $!");
				print OUT ($parent_name."\t".$parent."\t".join(";",@rRNA_count)."\n");
				close OUT;
			}
			$printed_taxons{$parent} = 1;
			$org = $parent;
		}
	}
}

###############################################################################
## Subroutines
###############################################################################

# Checks to see if the ranking of an organim is a desirable classification
sub desirable_rank {
	my $supplied_rank = $_[0];
	foreach my $rank (@preferred_ranks){
		if($supplied_rank eq $rank){
			return 1;
		}
	}
}
