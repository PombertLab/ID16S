#!/usr/bin/python

from statistics import mode
from sys import argv
import matplotlib.pyplot as plt

raw_data = {}
genes = {}
file = argv[1]
with open(file,"r") as FILE:
	for line in FILE.readlines():
		if(line[0] != "#"):
			name,taxid,gene,rRNA = line.split("\t")
			rRNA = rRNA.split(";")
			rRNA = [int(i) for i in rRNA]
			genes[name] = int(gene)
			raw_data[name] = rRNA


## Find the contribution to the contribution for each possible rRNA count when all other members of the sample are held at the min, max, and mode
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

gene_sum = sum(genes.values())
gene_norm = {}
for key,val in genes.items():
	gene_norm[key] = val/gene_sum

data = [i for i in compositions.values()]
data = data[::-1]
gene_data = [i for i in gene_norm.values()]
gene_data = gene_data[::-1]

# fig, a1 = plt.subplots()
fig, a2 = plt.subplots()
# a1.boxplot(raw_data.values(),labels=raw_data.keys(),vert=False,whis=(0,100))
# a1.set_xlim(0)
a2.boxplot(data,labels=raw_data.keys(),vert=False,showfliers=False)#,whis=(0,100))
a2.scatter(gene_data,[i for i in range(1,len(gene_norm)+1)])
# a2.set_xlim(0)
plt.xlim(0)
plt.show()
