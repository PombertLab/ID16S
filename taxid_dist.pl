#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'taxid_dist.pl';
my $version = '0.7';
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
-b (--blast)	NCBI blast output file(s) in outfmt 6 format
-e (--evalue)	evalue cutoff [Default: 1e-75]
-h (--hits)	Number of BLAST hits to keep; top N hits [Default: 1]
-o (--output)	Output files by taxonomic ranks [Default: species genus family order class]
		# Possible taxonomic rank options are:
		# subspecies strain species genus family order class phylum superkingdom
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$options\n" unless @ARGV;

my $node;
my $namedmp;
my @blast = ();
my $evalue = 1e-75;
my $maxhits = 1;
my @outputs = ('species', 'genus', 'family', 'order', 'class');
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
		$taxid{$txid}[0] = $description;
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
		$taxid{$txid}[1] = $rank;
		$taxid{$txid}[2] = $parent_txid;
	}
	else{ print "TaxID $txid not found in DB!\n"; } ## Debugging line, if needed
}
if ($verbose){
	print "\nPossible taxonomic ranks:\n";
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
				if (exists $taxid{$staxids}){ species(); }
			}
			else{
				$bhits{$query} = 1;
				if (exists $taxid{$staxids}){ species(); }
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
				my $label = $taxid{$key}[0];
				my $av = sprintf("%.2f%%", ($blasts{$ext}{$key}/$counts{$ext})*100);
				print OUT "$label\t$key\t$blasts{$ext}{$key}\t$av\n";
			}
		}
		else { print "No data found for taxonomic rank: $ext\n"; } ## Debugging message, if any
	}
}

## Subroutine
sub species{
	my $id = $staxids;
	for (0..20){
		my $rank = $taxid{$id}[1]; ## Taxonomic rank could be strain, species, genus, family...
		my $desc = $taxid{$id}[0]; ## Description of said rank
		$blasts{$rank}{$id} += 1; ## Tracking number of instances
		$counts{$rank}++;  ## Tracking number of instances
		last if ($rank eq 'superkingdom'); ## Stop if rank is superkingdom
		$id = $taxid{$id}[2]; ## Rank is now its parent.
	}
}
