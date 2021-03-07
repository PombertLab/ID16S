#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'taxid_dist.pl';
my $version = '0.4';
my $updated = '06/03/2021';

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
		  -b Examples/*.blastn \\
		  -e 1e-75 \\
		  -h 1

OPTIONS:
-n (--nodes)	NCBI nodes.dmp file 
-a (--names)	NCBI names.dmp
-b (--blast)	NCBI blast output file(s) in oufmt 6 format
-e (--evalue)	evalue cutoff [Default: 1e-75]
-h (--hits)	Number of BLAST hits to keep; top N hits [Default: 1]
OPTIONS
die "\n$options\n" unless @ARGV;

my $node;
my $namedmp;
my @blast = ();
my $evalue = 1e-75;
my $maxhits = 1;
GetOptions(
	'n|nodes=s' => \$node,
	'a|names=s' => \$namedmp,
	'b|blast=s@{1,}' => \@blast,
	'e|value=s' => \$evalue,
	'h|hits=i' => \$maxhits
);

## Initializing taxids -> names database
my %taxid;
open NAMES, "<", "$namedmp" or die "Can't read file $namedmp $!\n";
print "Initializing taxonomic IDs...\n";

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
print "Initializing taxonomic databases...\n";

while (my $line = <NODES>){

	chomp $line; $line =~ s/\t\|//g;
	my @columns = split("\t", $line);
	my $txid = $columns[0];
	my $parent_txid = $columns[1];
	my $rank = $columns[2];

	### for (sort keys %ranks){ print "$_\n"; }
    ###  Rank types:
    # biotype, clade, class, cohort, family, forma, forma specialis, genotype, genus, infraclass, infraorder
    # isolate, kingdom, morph, norank, order, parvorder, pathogroup, phylum, section, series, serogroup, serotype
    # species, species group, species subgroup, strain, subclass, subcohort, subfamily, subgenus, subkingdom
    # suborder, subphylum, subsection, subspecies, subtribe, subvariety, superclass, superfamily, superkingdom
    # superorder, superphylum, tribe, varietas

    if (exists $taxid{$txid}){
	    $ranks{$rank}{$txid}[0] = $taxid{$txid};
	    $ranks{$rank}{$txid}[1] = $parent_txid;
    }
    else{ print "TaxID $txid not found in DB!\n"; } ## Debugging line
}

## Working on BLAST taxonomized outfmt6 files; treating each file as independent datasets
## -outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames'
my %bhits; my %blasts; my %counts; my $staxids;
while (my $blast = shift@blast){

	print "Parsing $blast...\n";
	open BLAST, "<", "$blast" or die "Can't read file: $blast $!\n";

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
				elsif (exists $ranks{'subspecies'}{$staxids}){
                    subspecies();
                }
				elsif (exists $ranks{'species'}{$staxids}){
                    species();
                }
				else {
					print "WARNING: Taxonomy ID $staxids isn't a species, subspecies, or incertae sedis.";
					if (exists $ranks{'strain'}{$staxids}){print " txid$staxids is a strain";}
					print "\n";
					## Would need to implement a sub for strains, stuctures look off though
				}
			}
			else{
				$bhits{$query} = 1;
				if (exists $ranks{'norank'}{$staxids}){$blasts{'norank'}{$staxids} += 1; $counts{'norank'}++;}
				elsif (exists $ranks{'subspecies'}{$staxids}){
                    subspecies();
                }
				elsif (exists $ranks{'species'}{$staxids}){
                    species();
                }
				else {
					print "WARNING: Taxonomy ID $staxids isn't a species, subspecies, or incertae sedis.";
					if (exists $ranks{'strain'}){print " txid$staxids is a strain";}
					print "\n";
					## Would need to implement a sub for strains, stuctures look off though
				}
			}
		}
	}
	my $size;
    my @ext = ('subspecies', 'species', 'genus', 'family', 'order', 'class', 'phylum', 'norank');
    for my $ext (@ext){
        if ($counts{$ext}){
            open OUT, ">", "$blast.$ext";
            print OUT "$ext\tTaxIF\tNumber\tPercent (total = $counts{$ext})\n";
            foreach (sort {$blasts{$ext}{$b} <=> $blasts{$ext}{$a}} keys %{$blasts{$ext}}){
                my $av = sprintf("%.2f%%", ($blasts{$ext}{$_}/$counts{$ext})*100);
                print OUT "$taxid{$_}\t$_\t$blasts{$ext}{$_}\t$av\n";
            }  
        }
        else {
            print "No data found for rank: $ext\n";
        }
    }   
}

## Subroutines
sub subspecies{
    no warnings; ## Removing unnecessary verbosity is species is not defined.
	$blasts{'subspecies'}{$staxids} += 1; $counts{'subspecies'}++;
	$blasts{'species'}{$ranks{'subspecies'}{$staxids}[1]} += 1; $counts{'species'}++;
	$blasts{'bgenus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]} += 1; $counts{'genus'}++;
	$blasts{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]} += 1; $counts{'family'}++;
	$blasts{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]} += 1; $counts{'order'}++;
	$blasts{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'class'}++;
	$blasts{'phylum'}{$ranks{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$ranks{'subspecies'}{$staxids}[1]}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'phylum'}++;
}
sub species{
	no warnings; ## Removing unnecessary verbosity is species is not defined.
    $blasts{'species'}{$staxids} += 1; $counts{'species'}++;
	$blasts{'genus'}{$ranks{'species'}{$staxids}[1]} += 1; $counts{'genus'}++;
	$blasts{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]} += 1; $counts{'family'}++;
	$blasts{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]} += 1; $counts{'order'}++;
	$blasts{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]}[1]} += 1; $counts{'class'}++;
	$blasts{'phylum'}{$ranks{'class'}{$ranks{'order'}{$ranks{'family'}{$ranks{'genus'}{$ranks{'species'}{$staxids}[1]}[1]}[1]}[1]}[1]} += 1; $counts{'phylum'}++;
}