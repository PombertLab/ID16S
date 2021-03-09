#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'taxid_dist.pl';
my $version = '0.5a';
my $updated = '09/03/2021';

use strict; use warnings; use Getopt::Long qw(GetOptions);

### Defining options
my $options = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}

SYNOPSIS	Generates a distribution of sequences per species, genus, family and so forth from taxonomized BLAST output files.
		This script was created to handle megablast analyses of nanopore 16S amplicon sequencing. Because of the error
		rate of nanopore sequencing, identification at the species/subspecies level can be ambiguous and should not be
		taken at face value. Values at the genus level should be more accurate.

REQUIREMENTS	- ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
		- BLAST outfmt: -outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames'

COMMAND		${name} \\
		  -n TaxDumps/nodes.dmp \\
		  -a TaxDumps/names.dmp \\
		  -b Examples/*.megablast \\
		  -e 1e-75 \\
		  -h 1 \\
		  -o species genus family order class phylum \\
		  -v

OPTIONS:
-n (--nodes)	NCBI nodes.dmp file 
-a (--names)	NCBI names.dmp
-b (--blast)	NCBI blast output file(s) in oufmt 6 format
-e (--evalue)	evalue cutoff [Default: 1e-75]
-h (--hits)	Number of BLAST hits to keep; top N hits [Default: 1]
-o (--output)	Output files by taxonomic ranks [Default: species genus family]
		# Possible taxonomic rank options are:
		# subspecies strain species genus family order class phylum
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$options\n" unless @ARGV;

my $node;
my $namedmp;
my @blast = ();
my $evalue = 1e-75;
my $maxhits = 1;
my @outputs = ('species', 'genus', 'family');
my $verbose;
GetOptions(
	'n|nodes=s' => \$node,
	'a|names=s' => \$namedmp,
	'b|blast=s@{1,}' => \@blast,
	'e|value=s' => \$evalue,
	'h|hits=i' => \$maxhits,
	'o|outputs=s@{1,}' => \@outputs,
	'v|verbose' => \$verbose
);

## Initializing taxids -> names database
my %taxid;
open NAMES, "<", "$namedmp" or die "Can't read file $namedmp $!\n";
if ($verbose){ print "\nInitializing taxonomic IDs...\n"; }

while (my $line = <NAMES>){
	chomp $line; $line =~ s/\t\|//g;
	if ($line =~ /scientific name/){
		my @columns = split("\t", $line);
		my $txid = $columns[0];
		my $description = $columns[1];
		$taxid{$txid} = $description;
	}
}

### Initializing taxonomic databases
my %ranks;
open NODES, "<", "$node" or die "Can't read file $node $!\n";
if ($verbose){ print "Initializing taxonomic databases...\n"; }

while (my $line = <NODES>){

	chomp $line; $line =~ s/\t\|//g;
	my @columns = split("\t", $line);
	my $txid = $columns[0];
	my $parent_txid = $columns[1];
	my $rank = $columns[2];

	###  Rank types:
	# biotype, clade, class, cohort, family, forma, forma specialis, genotype, genus, infraclass, infraorder
	# isolate, kingdom, morph, no rank, order, parvorder, pathogroup, phylum, section, series, serogroup, serotype
	# species, species group, species subgroup, strain, subclass, subcohort, subfamily, subgenus, subkingdom
	# suborder, subphylum, subsection, subspecies, subtribe, subvariety, superclass, superfamily, superkingdom
	# superorder, superphylum, tribe, varietas

	if (exists $taxid{$txid}){
		$ranks{$rank}{$txid}[0] = $taxid{$txid};
		$ranks{$rank}{$txid}[1] = $parent_txid;
		$ranks{$rank}{$txid}[2] = $rank;
	}
	else{ print "TaxID $txid not found in DB!\n"; } ## Debugging line
}
if ($verbose){
	print "\nFound taxonomic ranks:\n";
	for (sort keys %ranks){ print "$_\n"; }
	print "\n";
}

## Working on BLAST taxonomized outfmt6 files; treating each file as independent datasets
## -outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames'
my %bhits; my %blasts; my %counts; my $staxids;
while (my $blast = shift@blast){

	open BLAST, "<", "$blast" or die "Can't read file: $blast $!\n";
	if ($verbose){ print "Parsing $blast...\n"; }

	%bhits = (); %blasts = (); %counts = ();

	while (my $line = <BLAST>){

		chomp $line;
		my @col = split("\t", $line);
		my $query = $col[0];    ## $col[0] = qseqid; $col[1] = sseqid; $col[2] = pident; $col[3] = length; $col[4] = bitscore; 
		my $ev = $col[5];       ## $col[5] = evalue; $col[6] = staxids; $col[7] = sskingdoms; $col[8] = sscinames; $col[9] = sblastnames
		$staxids = $col[6];
		if ($staxids =~ /^(\d+);/){$staxids = $1;} ## Searching for multiple taxids, keeping only the 1st one

		if ($ev <= $evalue){
			if ((exists $bhits{$query}) && ($bhits{$query} >= $maxhits)){next;}
			elsif ((exists $bhits{$query}) && ($bhits{$query} < $maxhits)){
				$bhits{$query}++;
				if (exists $ranks{'norank'}{$staxids}){$blasts{'norank'}{$staxids} += 1; $counts{'norank'}++;}
				elsif (exists $ranks{'subspecies'}{$staxids}){ subspecies(); }
				elsif (exists $ranks{'species'}{$staxids}){ species(); }
				elsif (exists $ranks{'strain'}{$staxids}){ strains(); }
				else { print " txid$staxids taxonomic rank is unclear: $taxid{$staxids}\n"; }
			}
			else{
				$bhits{$query} = 1;
				if (exists $ranks{'norank'}{$staxids}){$blasts{'norank'}{$staxids} += 1; $counts{'norank'}++;}
				elsif (exists $ranks{'subspecies'}{$staxids}){ subspecies(); }
				elsif (exists $ranks{'species'}{$staxids}){ species(); }
				elsif (exists $ranks{'strain'}){ strains(); }
				else { print " txid$staxids taxonomic rank is unclear: $taxid{$staxids}\n"; }
			}
		}
	}

	## Working on output files
	my $size;
	my @ext = @outputs;
	for my $ext (@ext){
		if ($counts{$ext}){
			open OUT, ">", "$blast.$ext" or die "Can't create file: $blast.$ext $!\n";
			print OUT "$ext\tTaxID\tNumber\tPercent (total = $counts{$ext})\n";
			foreach my $key (sort {$blasts{$ext}{$b} <=> $blasts{$ext}{$a}} keys %{$blasts{$ext}}){
				
				my $label; ## NOTE: the nodes.dmp sometimes includes taxid called 'no rank'
				if (!defined $taxid{$key}){ $label = 'Undef rank'; }
				else { $label = $taxid{$key}; }

				my $av = sprintf("%.2f%%", ($blasts{$ext}{$key}/$counts{$ext})*100);
				print OUT "$label\t$key\t$blasts{$ext}{$key}\t$av\n";
			}
		}
		else { print "No data found for taxonomic rank: $ext\n"; }
	}
}

## Subroutines
## NOTE: the nodes.dmp sometimes includes taxid called 'no rank'
## Messes up the reconstruction based on parents. Must fix that...
## Probably needs to restuct the subs accordingly
sub subspecies{ 
	no warnings; ## Removing unnecessary verbosity is species is not defined.
	## Autoincrement subspecies, then its parents (species, genus, family...) + autoincrementing them
	$blasts{'subspecies'}{$staxids} += 1; $counts{'subspecies'}++;
	$blasts{'species'}{$ranks{'subspecies'}{$staxids}[1]} += 1; $counts{'species'}++;
	$blasts{'bgenus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]} += 1; $counts{'genus'}++;
	$blasts{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]} += 1; $counts{'family'}++;
	$blasts{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]} += 1; $counts{'order'}++;
	$blasts{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'class'}++;
	$blasts{'phylum'}{$ranks{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'phylum'}++;
}
sub strains{ 
	no warnings; ## Removing unnecessary verbosity is species is not defined.
	## Autoincrement strain, then its parents (species, genus, family...) + autoincrementing them
	$blasts{'strain'}{$staxids} += 1; $counts{'strain'}++;
	$blasts{'species'}{$ranks{'subspecies'}{$staxids}[1]} += 1; $counts{'species'}++;
	$blasts{'bgenus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]} += 1; $counts{'genus'}++;
	$blasts{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]} += 1; $counts{'family'}++;
	$blasts{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]} += 1; $counts{'order'}++;
	$blasts{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'class'}++;
	$blasts{'phylum'}{$ranks{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'phylum'}++;
}
sub species{
	no warnings; ## Removing unnecessary verbosity is species is not defined.
	## Autoincrement species, then its parents (genus, family, order...) + autoincrementing them
	$blasts{'species'}{$staxids} += 1; $counts{'species'}++;
	$blasts{'genus'}{$ranks{'species'}{$staxids}[1]} += 1; $counts{'genus'}++;
	$blasts{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]} += 1; $counts{'family'}++;
	$blasts{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]} += 1; $counts{'order'}++;
	$blasts{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]}[1]} += 1; $counts{'class'}++;
	$blasts{'phylum'}{$ranks{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'phylum'}++;
}