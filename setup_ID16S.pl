#!/usr/bin/perl
## Pombert Lab 2022
my $name = 'setup_ID16S.pl';
my $version = '0.2';
my $updated = '2022-04-01';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use File::Path qw(make_path);
use Cwd qw(abs_path);

my $usage = <<"EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Creates and stores ID16S environment variables to a configuration file.

USAGE		${name} \\
		  -c ID16S.sh \\
		  -d ./ID16S_DB

OPTIONS
-c (--config)	Configuration file [Default: ~/.bashrc]
-d (--db_dir)	Desired directory to download NCBI databases
-i (--inst_dir)	ID16S installation directory [Default: ./] 
EXIT

die ("\n$usage\n") unless (@ARGV);

my $path = fileparse($0);
my $db_path = './ID16S_DB';
my $config_file = '~/.bashrc';

GetOptions(
	'i|inst_dir=s' => \$path,
	'd|db_dir=s' => \$db_path,
	'c|config=s' => \$config_file,
);

unless (-d $db_path){
	make_path($db_path,{mode=>0755}) or die("Unable to create database directory $db_path: $!\n");
}

open CONFIG, ">>", $config_file or die("Unable to access to configuration file $config_file: $!\n");

###################################################################################################
## ID16S_HOME and ID16S_DB variables
###################################################################################################

print CONFIG ("\n".'# Adding ID16S home and database variables'."\n");
print CONFIG ('export ID16S_HOME='.abs_path($path)."\n");
print CONFIG ('export ID16S_DB='.abs_path($db_path)."\n");

print CONFIG ("\n");

###################################################################################################
## BLASTDB update with TaxDB
###################################################################################################

print CONFIG ('# Adding NCBI TaxDB to BLASTDB variable'."\n");
print CONFIG ('export BLASTDB=$BLASTDB:$ID16_DB/TaxDB'."\n");

close CONFIG;