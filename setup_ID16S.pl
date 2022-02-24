#!/usr/bin/perl
## Pombert Lab 2022
my $name = 'setup_ID16S.pl';
my $version = '0.1';
my $updated = '2022-02-24';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Cwd qw(abs_path);
use File::Path qw(make_path);

my $usage = <<"EXIT";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	The purpose of this script is to add ID16S enviroment variables
		to a configuration file.

USAGE		${name} \\


OPTIONS
-c (--config)	Configuration file [Default: ~/.bashrc]
-w (--work_dir)	Desired working directory for ID16S
EXIT

die("\n$usage\n") unless(@ARGV);

my $path = './ID16S';
my $config_file = '~/.bashrc';

GetOptions(
	'w|work_dir=s' => \$path,
);

my $dbpath = "$path/ID16S_DB";

unless(-d $path){
	make_path($dbpath,{mode=>0755}) or die("Unable to create database directory $dbpath: $!\n");
}

open CONFIG, ">>", $config_file or die("Unable to create configuration file $config_file: $!\n");

###################################################################################################
## ID16S_HOME and ID16S_DB variables
###################################################################################################

print CONFIG ("\n".'# Adding ID16S home and database variables'."\n");
print CONFIG ('export ID16S_HOME='.abs_path($path)."\n");
print CONFIG ('export ID16S_DB='.abs_path($dbpath)."\n");

print CONFIG ("\n");

###################################################################################################
## BLASTDB update with TaxDB
###################################################################################################

print CONFIG ('# Adding NCBI TaxDB to BLASTDB variable'."\n");
print CONFIG ('export BLASTDB=$BLASTDB:$ID16_DB/TaxDB'."\n");

close CONFIG;

system "source $config_file";