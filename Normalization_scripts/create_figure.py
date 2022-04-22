#!/usr/bin/python

name = 'create_distribution_figure.py'
version = '0.3'
updated = '2022-04-22'

from sys import argv
from statistics import mode
import argparse
import matplotlib.pyplot as plt

usage = f'''
NAME		{name}
VERSION		{version}
UPDATED		{updated}
SYNOPSIS	Takes the normalization log file from get_organism_statistics.pl
		to create an rRNA distribution figure displaying possible contribution
		to the composition of the microbiome.

USAGE		{name} \\
		  -i barcode_11_fasta_megablast_genus_Normalized_Microbiome_Count.log

OPTIONS
-i (--input)	Normalization log file
-d (--display)	Display figure
-c (--cutoff)	Hide taxons below a certain contribution [Default = .01]
-s (--save)	Save figure
-o (--out)	File name to save figure under [Default: distribution_figure]
-f (--format)	Save format (.png,.eps,.jpg,.jpeg,.pdf,.pgf,.ps,.raw,.rgba,.svg,.svgz,.tif,.tiff) [Default: .svg]
'''

if len(argv) < 2:
	print(f"\n{usage}\n")
	exit()

parser = argparse.ArgumentParser()
parser.add_argument('-i','--input',required=True)
parser.add_argument('-d','--display',action='store_true')
parser.add_argument('-c','--cutoff',default=.01)
parser.add_argument('-s','--save',action='store_true')
parser.add_argument('-o','--out',default="distribution_figure")
parser.add_argument('-f','--format',default=[".svg"],nargs="*")

args = parser.parse_args()
show = args.display
cutoff = args.cutoff
save = args.save
file = args.input
out = args.out
format_types = args.format

raw_data = {}
genes = {}
with open(file,"r") as FILE:
	for line in FILE.readlines():
		if(line[0] != "#"):
			name,taxid,gene,rRNA = line.split("\t")
			rRNA = rRNA.split(";")
			rRNA = [int(i) for i in rRNA]
			genes[name] = int(gene)
			raw_data[name] = rRNA


## Find the contribution to the composition for each possible rRNA count when all other members of the sample are held at the min, max, and mode
compositions = {}
for org_o in raw_data.keys():
	min_comp = 0
	max_comp = 0
	avg_comp = 0
	for org_i in raw_data.keys():
		if(org_i != org_o):
			min_comp += (genes[org_i]/min(raw_data[org_i]))
			max_comp += (genes[org_i]/max(raw_data[org_i]))
			avg_comp += (genes[org_i]/int(mode(raw_data[org_i])))
	compositions[org_o] = []
	for datum in raw_data[org_o]:
		compositions[org_o].append((genes[org_o]/datum)/(min_comp+(genes[org_o]/datum)))
		compositions[org_o].append((genes[org_o]/datum)/(max_comp+genes[org_o]/datum))
		compositions[org_o].append((genes[org_o]/datum)/(avg_comp+genes[org_o]/datum))
	if max(compositions[org_o]) < cutoff:
		del compositions[org_o]
gene_sum = sum(genes.values())
gene_norm = {}
for key,val in genes.items():
	gene_norm[key] = val/gene_sum

data = [i for i in compositions.values()]
data = data[::-1]
gene_data = [gene_norm[i] for i in compositions.keys()]
gene_data = gene_data[::-1]
labels = [i for i in compositions.keys()]
labels = labels[::-1]

fig, a1 = plt.subplots()
a1.boxplot(data,labels=labels,vert=False,showfliers=False)
a1.scatter(gene_data,[i for i in range(1,len(compositions.keys())+1)],label="Non-normalized contribution")
plt.legend()
plt.xlim(0)
plt.tight_layout()

if save:
	for format_type in format_types:
		format_type = format_type.replace(".","")
		plt.savefig(f"{out}.{format_type}",format=format_type,transparent=True)

if show:
	plt.show()
