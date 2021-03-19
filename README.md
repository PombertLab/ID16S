## Table of contents
* [Introduction](#Introduction)
* [Dependencies](#Dependencies)
* [Installation](#Installation)
* [Key steps](#Key-steps)
* [Example](#Example)
* [References](#References)

## Introduction
The ID16S pipeline reconstructs the composition of bacterial species from a multifasta file of 16S amplicon sequences. Inferences are derived from [BLAST](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/) homology searches against the NCBI 16S Microbial database. This pipeline was tested on Nanopore 1D reads obtained with the 16S Barcoding Kit (SQK-RAB204). Identification accuracy parallels that of the Nanopore sequencing reads. This pipeline should work on all 16S datasets but longer sequencing reads are preferable.

Note that for large datasets, BLAST homology searches will take a while to complete, even with the megablast algorithm. People interested in faster tools should look at [Kraken2](https://github.com/DerrickWood/kraken2/wiki). The later is based on kmers and is much faster than BLAST approaches but produces a lower recall with Nanopore reads due to their lower acccuracy. For an excellent comparison of the recall rate from nanopore reads with BLAST and Kraken2, see this [paper](https://doi.org/10.1186/s12859-020-3528-4) by Pearman *et al.*

## Dependencies
- [Perl 5](https://www.perl.org/)
- [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

#### Optional
- [guppy](https://nanoporetech.com/) (for FAST5 basecalling)

## Installation
To download this pipeline from the command line with Git, then add it to the $PATH variable (for the current session), type:
```Bash
git clone https://github.com/PombertLab/ID16S.git
cd ID16S/
export PATH=$PATH:$(pwd)
```

A total of 3 NCBI datasets are required for the ID16S pipeline:
1. The NCBI 16S Microbial database - [16S_ribosomal_RNA.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/16S_ribosomal_RNA.tar.gz)
2. The NCBI Taxonomy database - [taxdb.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz)
3. The NCBI Taxonomy dumps - [taxdump.tar.gz](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz)

These datasets can be downloaded manually or with [download_DBs.sh](https://github.com/PombertLab/ID16S/blob/master/download_DBs.sh). The later will download the NCBI datasets files in the current directory. To use it, simply type:
```Bash
download_DBs.sh
```

The NCBI Taxonomy database must be set in the BLASTDB environment variables. To set it for the current session, type:
```Bash
export BLASTDB=$BLASTDB:$(pwd)/TaxDB
```

## Key steps
The ID16S pipeline consists of a few simple steps:
1. Optional - Basecall Nanopore FAST5 files with [guppy](https://nanoporetech.com/)
2. Convert FASTQ files to FASTA format with [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl)
3. Perform homology searches against the Microbial 16S database with [megablast.pl](https://github.com/PombertLab/ID16S/blob/master/megablast.pl)
4. Summarize the taxonomic composition of the datasets with [taxid_dist.pl](https://github.com/PombertLab/ID16S/blob/master/taxid_dist.pl)

## Example
We can use the FASTQ files located in the Example/ folder to test the installation of the pipeline. To convert the FASTQ files to FASTA format with [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl), simply type:
```Bash
fastq2fasta.pl \
   -f Example/*.fastq \
   -o FASTA \
   -v
```

Options for [fastq2fasta.pl](https://github.com/PombertLab/ID16S/blob/master/fastq2fasta.pl) are:
```
-f (--fastq)	FASTQ files to convert
-o (--outdir)	Output directory [Default: ./]
-v (--verbose)	Adds verbosity
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
-d (--db)	NCBI 16S Microbial Database to query [default = 16S_ribosomal_RNA]
-e (--evalue)	1e-05, 1e-10 or other [default = 1e-05]
-c (--culling)	culling limit [default = 10]
-t (--threads)	CPUs to use [default = 10]
-o (--outdir)	Output directory [Default: ./]
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

## References
Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ. **Basic local alignment search tool.** *J Mol Biol.* 1990 Oct 5;215(3):403-10. doi: [10.1016/S0022-2836(05)80360-2](https://doi.org/10.1016/s0022-2836(05)80360-2). PMID: 2231712.

Wood DE, Lu J, Langmead B. **Improved metagenomic analysis with Kraken 2.** *Genome Biol.* 2019 Nov 28;20(1):257. doi: [10.1186/s13059-019-1891-0](https://doi.org/10.1186/s13059-019-1891-0). PMID: 31779668

Pearman WS, Freed NE, Silander OK **Testing the advantages and disadvantages of short- and long- read eukaryotic metagenomics using simulated reads** *BMC Bioinformatics*. 2020 May 29;21(1):220. doi: [10.1186/s12859-020-3528-4](https://doi.org/10.1186/s12859-020-3528-4). PMID: 32471343