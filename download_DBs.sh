#!/usr/bin/bash

NCBI_16S=NCBI_16S/
TaxDB=TaxDB/
TaxDumps=TaxDumps/

mkdir $NCBI_16S $TaxDB $TaxDumps
echo "Downloading NCBI 16S Database"
cd $NCBI_16S;
wget ftp://ftp.ncbi.nih.gov/blast/db/16SMicrobial.tar.gz
tar -zxvf 16SMicrobial.tar.gz
rm 16SMicrobial.tar.gz

echo "Downloading NCBI Taxonomy Database"
cd ../$TaxDB
wget ftp://ftp.ncbi.nih.gov/blast/db/taxdb.tar.gz
tar -zxvf taxdb.tar.gz
rm taxdb.tar.gz

echo "Downloading NCBI Taxonomy dump files"
cd ../$TaxDumps
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -zxvf taxdump.tar.gz
rm taxdump.tar.gz
cd ../

