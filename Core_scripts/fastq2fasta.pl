#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'fastq2fasta.pl';
my $version = '0.3a';
my $updated = '2022-03-24';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use PerlIO::gzip;

## Defining options
my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Converts FASTQ files to FASTA format (no quality scores)

COMMAND		${name} \\
		  -f *.fastq \\
		  -o FASTA \\
		  -h 50 \\
		  -v

OPTIONS:
-f (--fastq)	FASTQ files to convert
-o (--outdir)	Output directory [Default: ./]
-h (--headcrop)	Remove the first X nucleotides from 5' ## Useful for nanopore data
-v (--verbose)	Adds verbosity
OPTIONS
die "\n$usage\n" unless @ARGV;

my @fq;
my $outdir = './';
my $headcrop;
my $verbose;
GetOptions(
	'f|fastq=s@{1,}' => \@fq,
	'o|outdir=s' => \$outdir,
	'h|headcrop=i' => \$headcrop,
	'v|verbose' => \$verbose
);

## Creating directory
unless (-d $outdir){
	mkdir ($outdir, 0755) or die "Can't create output directory $outdir: $!\n";
}
if ($verbose){ print "\nFASTA output directory: $outdir\n"; }

## Working on fastq files
while (my $fastq = shift@fq){

	my $gzip = '';
	if ($fastq =~ /.gz$/){ $gzip = ':gzip'; }

	open FASTQ, "<$gzip", "$fastq" or die "Can't read file: $fastq $!\n";
	my $basename = fileparse($fastq);
	if ($fastq =~ /.gz$/){
		$basename =~ s/.\w+\.gz$//;
	}
	else {
		$basename =~ s/.\w+$//
	}
	open FASTA, ">", "${outdir}/$basename.fasta" or die "Can't create file: $basename.fasta $!\n";

	my $line_counter = 0;
	my $read_name;
	my $read_number;
	my @lengths;

	while (my $line = <FASTQ>){

		chomp $line;
		$line_counter++;

		## Line 1 = Read name
		if ($line_counter == 1){
			$read_name = $line;
			$read_number++;
		}
		## Line 2 = Read sequence
		elsif ($line_counter == 2){

			my $sequence = $line;
			my $read_length = length $sequence;

			## Adding leading zeroes to help sort array
			my $padded_length = sprintf("%09d", $read_length);
			push (@lengths, $padded_length);

			## Remove first X nucleotides if headcrop; useful for Nanopore data
			if ($headcrop){
				$sequence = substr($sequence, $headcrop, $read_length);
			}

			## Keeping only 1st part of sequence names before whitespaces
			my ($seqname) = $read_name =~ /^@(\S+)/;
			print FASTA ">$seqname\n";

			## Printing sequence
			my @fasta = unpack ("(A60)*", $sequence);
			while (my $seq = shift@fasta){
				print FASTA "$seq\n";
			}

		}
		## Lines 3 + 4 = Spacer + Quality score; skip + reset counter
		elsif ($line_counter == 3){ next; }
		elsif ($line_counter == 4){
			$line_counter = 0;
			next;
		}

	}

	if ($fastq =~ /.gz$/){ binmode FASTQ, ":gzip(none)"; }

	if ($verbose) {
		n50($fastq, @lengths);
	}

	close FASTQ;
	close FASTA;

}

### subroutines
sub n50{
	my @fh = (*STDOUT);
	my $file = shift @_;
	my $num_reads = scalar @_;
	my @len = sort @_; ## sort by size
	@len = reverse @len; ## from largest to smallest

	my $nreads = commify($num_reads);
	foreach (@fh){
		print $_ "\n## Metrics for dataset $file\n\n";
		print $_ "Number of reads: $nreads\n";
	}

	## Median
	my $median;
	my $median_pos = $num_reads/2;
	if ($median_pos =~ /^\d+$/){ $median = $len[$median_pos]; }
	else {
		my $med1 = int($median_pos);
		my $med2 = $med1 + 1;
		$median = (($len[$med1] + $len[$med2])/2);
	}

	## Average
	my $sum; foreach (@len){ $sum += $_; }
	my $fsum = commify($sum);
	my $large = sprintf("%.0f", $len[0]); $large = commify($large);
	my $small = sprintf("%.0f", $len[$#len]); $small = commify($small);
	my $average = sprintf("%.0f", ($sum/$num_reads)); $average = commify($average);
	$median = sprintf("%.0f", $median); $median = commify($median);
	foreach (@fh){
		print $_ "Total number of bases: $fsum\n";
		print $_ "Largest read = $large nt\n";
		print $_ "Smallest read = $small nt\n";
		print $_ "Average read size = $average nt\n";
		print $_ "Median read size = $median nt\n";
	}

	## N50, N75, N90
	my $n50_td = $sum*0.5; my $n75_td = $sum*0.75; my $n90_td = $sum*0.9;
	my $n50; my $n75, my $n90;
	my $nsum50 = 0; my $nsum75 = 0; my $nsum90 = 0;
	foreach (@len){ $nsum50 += $_; if ($nsum50 >= $n50_td){ $n50 = $_; last; }}
	foreach (@len){ $nsum75 += $_; if ($nsum75 >= $n75_td){ $n75 = $_; last; }}
	foreach (@len){ $nsum90 += $_; if ($nsum90 >= $n75_td){ $n90 = $_; last; }}
	$n50 = sprintf ("%.0f", $n50); $n50 = commify($n50);
	$n75 = sprintf ("%.0f", $n75); $n75 = commify($n75);
	$n90 = sprintf ("%.0f", $n90); $n90 = commify($n90);
	foreach (@fh){ print $_ "N50 = $n50 nt\n"."N75 = $n75 nt\n"."N90 = $n90 nt\n"."\n"; }
}

sub commify { ## From the Perl Cookbook; O'Reilly
	my $text = reverse $_[0];
	$text =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}