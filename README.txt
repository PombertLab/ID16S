SYNOPSIS
This pipeline reconstructs the composition of bacterial species from a multifasta file of 16S sequences.
Inferences are derived from BLAST homology searches against the NCBI 16S Microbial database.
This pipeline was tested on Nanopore 1D reads obtained from with the 16S Barcoding Kit (SQK-RAB204).
Identification accuracy parallels that of the Nanopore sequencing reads.
This pipeline should work on all 16S datasets but longer sequencing reads are preferable. 

REQUIREMENTS
- Perl
- BLAST+: ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
- NCBI 16S Microbial database: ftp://ftp.ncbi.nih.gov/blast/db/16SMicrobial.tar.gz
- NCBI Taxonomy database: ftp://ftp.ncbi.nih.gov/blast/db/taxdb.tar.gz
- NCBI Taxonomy dumps: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

OPTIONAL
- albacore (for FAST5 basecalling) - https://nanoporetech.com/

INSTALLATION

1) git clone https://github.com/PombertLab/Microbiomes.git

2) Downloading databases:
cd Microbiomes
chmod a+x *.pl *.sh
./download_DBs.sh ## Downloads the NCBI Microbial/Taxonomy databases and dump files in current directory

3) The NCBI Taxonomy database variable must be set in the environmental variables:
pwd ## print working directory
export BLASTDB=$BLASTDB:/path/to/working/directory/TaxDB

STEPS
1) Basecalling with Albacore (optional)
2) FASTQ to FASTA conversion
3) Megablastn analyses against the Microbial 16S database
4) Summarizing the results with taxid_dist.pl

EXAMPLES
a) megablast
./fastq2fasta.pl Examples/*.fastq
./megablast.pl -k megablast -q Examples/*.fasta -d NCBI_16S/16SMicrobial -e 1e-05 -c 10 -t 10
./taxid_dist.pl -n TaxDumps/nodes.dmp -a TaxDumps/names.dmp -b Examples/*.megablast -e 1e-75 -h 1

b) blastn
./fastq2fasta.pl Examples/*.fastq
./megablast.pl -k blastn -q Examples/*.fasta -d NCBI_16S/16SMicrobial -e 1e-05 -c 10 -t 10
./taxid_dist.pl -n TaxDumps/nodes.dmp -a TaxDumps/names.dmp -b Examples/*.blastn -e 1e-75 -h 1