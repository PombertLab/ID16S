# ID16S – 16S amplicon identification

<a href="https://doi.org/10.5281/zenodo.6587303"><p align="right"><img src="https://zenodo.org/badge/300303510.svg" al

## Table of contents
* [Introduction](#Introduction)
* [Dependencies](#Dependencies)
* [Installation](#Installation)
* [Running ID16S](#Running-ID16S-via-run_ID16S.pl)
* [Step by Step](#Running-ID16S-step-wise)
* [Example](#Example)
* [References](#References)

## Introduction
The ID16S pipeline reconstructs the composition of bacterial species from a multifasta file of 16S amplicon sequences. Inferences are derived from [BLAST](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/) homology searches against the NCBI 16S Microbial database. Normalization based on rRNA copy variation is performed by utilizing a database produced from all completely assembled bacterial genome annotations within [RefSeq](https://www.ncbi.nlm.nih.gov/refseq/). For a good overview of rRNA copy variation, please see this excellent [review](https://doi.org/10.1016/j.tim.2020.05.019) by Lavrinienko *et al.*

The ID16S pipeline was tested on Nanopore 1D reads obtained with the 16S Barcoding Kit (SQK-RAB204). Identification accuracy parallels that of the Nanopore sequencing reads. This pipeline should work on all 16S datasets but full length 16S amplicons are preferable.

Note that for large datasets, BLAST homology searches will take a while to complete, even with the megablast algorithm. People interested in faster tools should look at [Kraken2](https://github.com/DerrickWood/kraken2/wiki). The later is based on kmers and is much faster than BLAST approaches but produces a lower recall with Nanopore reads due to their lower acccuracy. For an excellent comparison of the recall rate from nanopore reads with BLAST and Kraken2, see this [paper](https://doi.org/10.1186/s12859-020-3528-4) by Pearman *et al.*

## Dependencies
- [Perl 5](https://www.perl.org/)
- [Python 3](https://www.python.org/)
- [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

## Getting started
<b>Installing ID16S</b>

The ID16S pipeline can be downloaded with Git:
```Bash
git clone --recursive https://github.com/PombertLab/ID16S.git
```

To run the ID16S pipeline, its environment variables must be setup:
```Bash
ID16S/setup_ID16S.pl \
  -w /desired/output/path \
  -d /desired/database/path \
  -c /desired/configuration/file

source $CONFIG_FILE
```

<b>Downloading databases</b>

A total of 3 NCBI datasets are required for the ID16S pipeline:
1. The NCBI 16S Microbial database - [16S_ribosomal_RNA.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/16S_ribosomal_RNA.tar.gz)
2. The NCBI Taxonomy database - [taxdb.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz)
3. The NCBI Taxonomy dumps - [taxdump.tar.gz](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz)

The ID16S pipeline comes with a precompiled 16S rRNA database (updated March 2022), though an updated version can be created.

The required databases can be downloaded as follows:
```Bash
ID16S/download_ID16S_dbs.pl -d
```

If an updated 16S rRNA database is desired, the addition of the `-c (--create)` flag can be used:
```Bash
ID16S/download_ID16S_dbs.pl -d -c
```

## Running ID16S via run_ID16S.pl

To run ID16S, provide [run_ID16S.pl](https://github.com/PombertLab/ID16S/blob/master/run_ID16S.pl) with the desired FASTA/Q files:
```Bash
ID16S/run_ID16S.pl \
  -fa /path/to/FASTA/files
  -fq /path/to/FASTQ/files
```

Options for run_ID16S.pl are:
```
GENERAL OPTIONS
-fa (--fasta)		FASTA files to run
-fq (--fastq)		FASTQ files to convert then run
-hd (--headcrop)	Remove the first X nucleotides from 5' end of FASTQ sequences
			## Useful for Nanopore data
-m (--min_length)	Minimum read length to keep from FASTQ files [Default: 1000]

ADVANCED OPTIONS
# ID16S SETTINGS
-o (--outdir)		Output directory [Default = \$ID16S_HOME]
-d (--db)		Path to 16IDS_DB download [Default = \$ID16S_DB]

# BLAST OPTIONS
-k (--tasks)		megablast, dc-megablast, blastn [default = megablast]
-t (--threads)		CPUs to use [default = 10]
-cu (--culling)		Culling limit [default = 10]
-h (--hits)		Number of hits to return [Default = 1]
-pe (--p_evalue)	Preliminary e-value cutoff for BLAST results [Default = 1e-05]

# OUTPUT OPTIONS
-r (--ranks)		Output files by taxonomic ranks [Default: species genus family order class]
-fe (--f_evalue)	Final e-value cutoff for BLAST results [Default = 1e-75]
-co (--concat)		Concatenate all results into a single file [Default: off]
```

The non-normalized results can be found in the <b>NonNormalized</b> directory, and will look similar to:
```Bash
==> EXAMPLE/NonNormalized/sample_1.fasta.megablast.class <==
class	TaxID	Number	Percent (total = 848)
Mollicutes	31969	848	100.00%

==> EXAMPLE/NonNormalized/sample_1.fasta.megablast.family <==
family	TaxID	Number	Percent (total = 848)
Mycoplasmataceae	2092	848	100.00%

==> EXAMPLE/NonNormalized/sample_1.fasta.megablast.genus <==
genus	TaxID	Number	Percent (total = 848)
Mycoplasmopsis	2767358	838	98.82%
Mycoplasma	2093	10	1.18%

==> EXAMPLE/NonNormalized/sample_1.fasta.megablast.order <==
order	TaxID	Number	Percent (total = 848)
Mycoplasmatales	2085	848	100.00%

==> EXAMPLE/NonNormalized/sample_1.fasta.megablast.species <==
species	TaxID	Number	Percent (total = 848)
Mycoplasmopsis fermentans	2115	677	79.83%
Mycoplasmopsis arginini	2094	134	15.80%
Mycoplasmopsis caviae	55603	22	2.59%
Mycoplasma canadense	29554	4	0.47%
Mycoplasmopsis hyopharyngis	29558	2	0.24%
Mycoplasma gateae	35769	2	0.24%
Mycoplasma neophronis	872983	1	0.12%
Mycoplasmopsis adleri	51362	1	0.12%
Mycoplasma auris	51363	1	0.12%
```

The normalized results can be found in the <i>Normalized</i> directory, and will look similar to:
```Bash
==> EXAMPLE/Normalized/sample_1_fasta_megablast_class_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Mollicutes	31969	class	100.00	100.00	0.00

==> EXAMPLE/Normalized/sample_1_fasta_megablast_family_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Mycoplasmataceae	2092	family	100.00	100.00	0.00

==> EXAMPLE/Normalized/sample_1_fasta_megablast_genus_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Mycoplasmopsis	2767358	genus	98.82	98.82	0.00
Mycoplasma	2093	genus	1.18	1.18	0.00

==> EXAMPLE/Normalized/sample_1_fasta_megablast_order_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Mycoplasmatales	2085	order	100.00	100.00	0.00

==> EXAMPLE/Normalized/sample_1_fasta_megablast_species_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Mycoplasmopsis fermentans	2115	species	79.83	88.79	8.96
Mycoplasmopsis arginini	2094	genus	15.80	8.79	-7.01
Mycoplasmopsis caviae	55603	genus	2.59	1.44	-1.15
Mycoplasma canadense	29554	genus	0.47	0.26	-0.21
Mycoplasma gateae	35769	genus	0.24	0.13	-0.11
Mycoplasmopsis hyopharyngis	29558	genus	0.24	0.13	-0.11
Mycoplasma neophronis	872983	genus	0.12	0.07	-0.05
Mycoplasmopsis mucosicanis	458208	genus	0.12	0.07	-0.05
Mycoplasma auris	51363	genus	0.12	0.07	-0.05
```

## Running ID16S step-wise

<b>Key steps</b>
The ID16S pipeline consists of a few simple steps:
1. Convert FASTQ files to FASTA format with [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl)
2. Perform homology searches against the Microbial 16S database with [megablast.pl](https://github.com/PombertLab/ID16S/blob/master/megablast.pl)
3. Summarize the taxonomic composition of the datasets with [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl)

## Example
We can use the FASTQ files located in the Example/ folder to test the installation of the pipeline. To convert the FASTQ files to FASTA format with [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl), simply type:
```Bash
fastq2fasta.pl \
   -f Example/*.fastq.gz \
   -h 50 \
   -m 1000 \
   -o FASTA \
   -v
```

Options for [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl) are:
```
-f (--fastq)		FASTQ files to convert
-o (--outdir)		Output directory [Default: ./]
-h (--headcrop)		Remove the first X nucleotides from 5' ## Useful for nanopore data
-m (--min_length)	Minimum length (in nt) of reads to keep [Default: 1000]
-v (--verbose)		Adds verbosity
```

To perform BLAST homology searches against the NCBI 16S ribosomal RNA database, we can use [megablast.pl](https://github.com/PombertLab/ID16S/blob/master/megablast.pl). This script will generate BLAST outputs with the following format: ***-outfmt '6 qseqid sseqid pident length bitscore evalue staxids sskingdoms sscinames sblastnames'***. This format is required for [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl).

To perform BLAST searches with [megablast.pl](https://github.com/PombertLab/ID16S/blob/master/megablast.pl) using 10 threads (-t 10), type:
``` Bash
megablast.pl \
   -k megablast \
   -q FASTA/*.fasta \
   -d NCBI_16S/16S_ribosomal_RNA \
   -e 1e-05 \
   -c 10 \
   -t 10 \
   -o MEGABLAST \
   -v
```

Options for [megablast.pl](https://github.com/PombertLab/ID16S/blob/master/megablast.pl) are:
```
-k (--task)	megablast, dc-megablast, blastn [default = megablast]
-q (--query)	fasta file(s) to be queried
-d (--db)	NCBI nucleotide database to query [default = 16S_ribosomal_RNA]
-e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
-c (--culling)	culling limit [default = 10]
-t (--threads)	CPUs to use [default = 10]
-o (--outdir)	Output directory [Default: ./]
-x (--taxids)	Restrict search to taxids from file ## one taxid per line
-n (--ntaxids)	Exclude from search taxids from file ## one taxid per line
-v (--verbose)	Adds verbosity
```

To reconstruct the composition of the datasets from the BLAST homology searches, we can use [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl). This script will generate output files per requested taxonomic rank, up to the superkingdom rank.

To use [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl), type:
```Bash
taxid_dist.pl \
   -n TaxDumps/nodes.dmp \
   -a TaxDumps/names.dmp \
   -b MEGABLAST/*.megablast \
   -e 1e-75 \
   -h 1 \
   -o SUMMARY \
   -r species genus family order class phylum \
   -v
```

Options for [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl) are:
```
-n (--nodes)	NCBI nodes.dmp file 
-a (--names)	NCBI names.dmp
-b (--blast)	NCBI blast output file(s) in outfmt 6 format
-e (--evalue)	evalue cutoff [Default: 1e-75]
-h (--hits)	Number of BLAST hits to keep; top N hits [Default: 1]
-o (--outdir)	Output directory [Default: ./]
-r (--ranks)	Output files by taxonomic ranks [Default: species genus family order class]
		# Possible taxonomic rank options are:
		# subspecies strain species genus family order class phylum superkingdom 'no rank'
-v (--verbose)	Adds verbosity
```

The output of [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl) should look like:
```Bash
head -n 5 SUMMARY/*

==> SUMMARY/sample_1.fasta.megablast.class <==
class	TaxID	Number	Percent (total = 848)
Mollicutes	31969	848	100.00%

==> SUMMARY/sample_1.fasta.megablast.family <==
family	TaxID	Number	Percent (total = 848)
Mycoplasmataceae	2092	848	100.00%

==> SUMMARY/sample_1.fasta.megablast.genus <==
genus	TaxID	Number	Percent (total = 848)
Mycoplasmopsis	2767358	837	98.70%
Mycoplasma	2093	11	1.30%

==> SUMMARY/sample_1.fasta.megablast.order <==
order	TaxID	Number	Percent (total = 848)
Mycoplasmatales	2085	848	100.00%

==> SUMMARY/sample_1.fasta.megablast.phylum <==
phylum	TaxID	Number	Percent (total = 848)
Tenericutes	544448	848	100.00%

==> SUMMARY/sample_1.fasta.megablast.species <==
species	TaxID	Number	Percent (total = 848)
Mycoplasma fermentans	2115	677	79.83%
Mycoplasma arginini	2094	134	15.80%
Mycoplasma caviae	55603	22	2.59%
Mycoplasma canadense	29554	5	0.59%

==> SUMMARY/sample_2.fasta.megablast.class <==
class	TaxID	Number	Percent (total = 809)
Bacilli	91061	809	100.00%

==> SUMMARY/sample_2.fasta.megablast.family <==
family	TaxID	Number	Percent (total = 809)
Staphylococcaceae	90964	799	98.76%
Bacillaceae	186817	7	0.87%
Listeriaceae	186820	1	0.12%
Enterococcaceae	81852	1	0.12%

==> SUMMARY/sample_2.fasta.megablast.genus <==
genus	TaxID	Number	Percent (total = 809)
Staphylococcus	1279	796	98.39%
Bacillus	1386	3	0.37%
Oceanobacillus	182709	1	0.12%
Halobacillus	45667	1	0.12%

==> SUMMARY/sample_2.fasta.megablast.order <==
order	TaxID	Number	Percent (total = 809)
Bacillales	1385	807	99.75%
Lactobacillales	186826	2	0.25%

==> SUMMARY/sample_2.fasta.megablast.phylum <==
phylum	TaxID	Number	Percent (total = 809)
Firmicutes	1239	809	100.00%

==> SUMMARY/sample_2.fasta.megablast.species <==
species	TaxID	Number	Percent (total = 809)
Staphylococcus kloosii	29384	696	86.03%
Staphylococcus casei	201828	24	2.97%
Staphylococcus hominis	1290	20	2.47%
Staphylococcus succinus	61015	15	1.85%
```

To normalize the composition by number of rRNA copies, we can use [get_organism_statistics.pl](https://github.com/PombertLab/ID16S/blob/master/get_organism_statistics.pl). This script will produce a file containing the rRNA-copy-normalized composition using the corresponding database for the taxonomic rank of the provided file.

The output will look similar to:
```Bash
==> EXAMPLE2/Normalized/sample_2_fasta_megablast_class_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Bacilli	91061	class	100.00	100.00	0.00

==> EXAMPLE2/Normalized/sample_2_fasta_megablast_family_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Staphylococcaceae	90964	family	98.76	98.86	0.10
Bacillaceae	186817	family	0.87	0.61	-0.26
Aerococcaceae	186827	family	0.12	0.22	0.10
Listeriaceae	186820	family	0.12	0.17	0.05
Enterococcaceae	81852	family	0.12	0.14	0.02

==> EXAMPLE2/Normalized/sample_2_fasta_megablast_genus_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Staphylococcus	1279	genus	98.39	98.51	0.12
Nosocomiicoccus	489909	genus	0.12	0.22	0.10
Salinicoccus	45669	genus	0.12	0.22	0.10
Bacillus	1386	genus	0.25	0.17	-0.08
Listeria	1637	genus	0.12	0.17	0.05
Halobacillus	45667	genus	0.12	0.12	0.00
Mammaliicoccus	2803850	genus	0.12	0.12	0.00
Alkalihalophilus	2893060	genus	0.12	0.11	-0.01
Vagococcus	2737	genus	0.12	0.11	-0.01

==> EXAMPLE2/Normalized/sample_2_fasta_megablast_order_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Bacillales	1385	order	99.75	99.38	-0.37
Lactobacillales	186826	order	0.25	0.62	0.37

==> EXAMPLE2/Normalized/sample_2_fasta_megablast_species_Normalized_Microbiome_Composition.tsv <==
###Organism Name	TaxID	Taxo Level	Non-normalized % of sample	Normalized % of sample	Delta
Staphylococcus kloosii	29384	genus	85.91	80.61	-5.30
Staphylococcus hominis	1290	species	2.60	8.52	5.92
Staphylococcus casei	201828	genus	2.97	2.78	-0.19
Staphylococcus succinus	61015	genus	1.98	1.86	-0.12
Staphylococcus croceilyticus	319942	genus	0.74	0.70	-0.04
Staphylococcus ureilyticus	94138	genus	0.62	0.58	-0.04
Staphylococcus gallinarum	1293	genus	0.37	0.35	-0.02
Staphylococcus equorum	246432	genus	0.37	0.35	-0.02
Staphylococcus carnosus	1281	species	0.25	0.32	0.07
```

## References
Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ. **Basic local alignment search tool.** *J Mol Biol.* 1990 Oct 5;215(3):403-10. PMID: 2231712 DOI: [10.1016/S0022-2836(05)80360-2](https://doi.org/10.1016/s0022-2836(05)80360-2).

Wood DE, Lu J, Langmead B. **Improved metagenomic analysis with Kraken 2.** *Genome Biol.* 2019 Nov 28;20(1):257. PMID: 31779668 PMCID: [PMC6883579](http://www.ncbi.nlm.nih.gov/pmc/articles/pmc6883579/) DOI: [10.1186/s13059-019-1891-0](https://doi.org/10.1186/s13059-019-1891-0).

Pearman WS, Freed NE, Silander OK **Testing the advantages and disadvantages of short- and long- read eukaryotic metagenomics using simulated reads** *BMC Bioinformatics*. 2020 May 29;21(1):220. PMID: 32471343 PMCID: [PMC7257156](http://www.ncbi.nlm.nih.gov/pmc/articles/pmc7257156/) DOI: [10.1186/s12859-020-3528-4](https://doi.org/10.1186/s12859-020-3528-4).

Lavrinienko A, Jernfors T, Koskimäki JJ, Pirttilä AM, Watts PC. **Does Intraspecific Variation in rDNA Copy Number Affect Analysis of Microbial Communities?**  *Trends Miccrobiol.* 2021 Jan;29(1):19-27. PMID: 32593503 DOI: [10.1016/j.tim.2020.05.019](https://doi.org/10.1016/j.tim.2020.05.019).
