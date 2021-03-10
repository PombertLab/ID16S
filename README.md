## Table of contents
* [Introduction](#Introduction)
* [Dependencies](#Dependencies)
* [Installation](#Installation)
* [Steps](#Steps)
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
The NCBI 16S Microbial database - [16S_ribosomal_RNA.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/16S_ribosomal_RNA.tar.gz)
The NCBI Taxonomy database - [taxdb.tar.gz](https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz)
The NCBI Taxonomy dumps - [taxdump.tar.gz](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz)

These datasets can be downloaded manually or with [download_DBs.sh](https://github.com/PombertLab/ID16S/blob/master/download_DBs.sh). The later will download the NCBI Microbial/Taxonomy databases and dump files in the current directory. To use it, simply type:
```Bash
download_DBs.sh
```


The NCBI Taxonomy database variable must be set in the environmental variables:
```Bash
cd TaxDB/
export BLASTDB=$BLASTDB:$(pwd)
cd ../
```

## Steps
1) Basecalling with guppy (optional)
2) FASTQ to FASTA conversion
3) Megablastn analyses against the Microbial 16S database (16S_ribosomal_RNA.tar.gz in NCBI v5)
4) Summarizing the results with taxid_dist.pl

## Example
#### a) megablast
```Bash
fastq2fasta.pl -f Examples/*.fastq

megablast.pl \
   -k megablast \
   -q Examples/*.fasta \
   -d NCBI_16S/16S_ribosomal_RNA \
   -e 1e-05 \
   -c 10 \
   -t 10

taxid_dist.pl \
   -n TaxDumps/nodes.dmp \
   -a TaxDumps/names.dmp \
   -b Examples/*.megablast \
   -e 1e-75 \
   -h 1
```

#### b) blastn
```Bash
fastq2fasta.pl Examples/*.fastq

megablast.pl \
   -k blastn \
   -q Examples/*.fasta \
   -d NCBI_16S/16SMicrobial \
   -e 1e-05 \
   -c 10 \
   -t 10

taxid_dist.pl \
   -n TaxDumps/nodes.dmp \
   -a TaxDumps/names.dmp \
   -b Examples/*.blastn \
   -e 1e-75 \
   -h 1
```

## References
Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ. **Basic local alignment search tool.** *J Mol Biol.* 1990 Oct 5;215(3):403-10. doi: [10.1016/S0022-2836(05)80360-2](https://doi.org/10.1016/s0022-2836(05)80360-2). PMID: 2231712.

Wood DE, Lu J, Langmead B. **Improved metagenomic analysis with Kraken 2.** *Genome Biol.* 2019 Nov 28;20(1):257. doi: [10.1186/s13059-019-1891-0](https://doi.org/10.1186/s13059-019-1891-0). PMID: 31779668

Pearman WS, Freed NE, Silander OK **Testing the advantages and disadvantages of short- and long- read eukaryotic metagenomics using simulated reads** *BMC Bioinformatics*. 2020 May 29;21(1):220. doi: [10.1186/s12859-020-3528-4](https://doi.org/10.1186/s12859-020-3528-4). PMID: 32471343