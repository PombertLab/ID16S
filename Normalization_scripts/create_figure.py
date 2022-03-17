#!/usr/bin/python

from statistics import mode
from sys import argv
import matplotlib.pyplot as plt
from time import sleep

from numpy import average

raw_data = {}
genes = {}
file = "/home/julian/julian/TEST/Normalized_Microbiome_Count.log"
with open(file,"r") as FILE:
	for line in FILE.readlines():
		if(line[0] != "#"):
			name,taxid,gene,rRNA = line.split("\t")
			rRNA = rRNA.split(";")
			rRNA = [int(i) for i in rRNA]
			genes[name] = int(gene)
			raw_data[name] = rRNA


contributions = {}
for org in raw_data.keys():
	contributions[org] = [max(raw_data[org]),min(raw_data[org]),mode(raw_data[org])]


compositions = {}
for org_o in raw_data.keys():
	min_comp = genes[org_o]/contributions[org_o][0]
	max_comp = genes[org_o]/contributions[org_o][1]
	avg_comp = genes[org_o]/contributions[org_o][2]
	for org_i in raw_data.keys():
		if(org_i != org_o):
			min_comp += (genes[org_i]/contributions[org_i][1])
			max_comp += (genes[org_i]/contributions[org_i][0])
			avg_comp += (genes[org_i]/contributions[org_i][2])
	min_per = genes[org_o]/contributions[org_o][0]/min_comp
	max_per = genes[org_o]/contributions[org_o][1]/max_comp
	avg_per = genes[org_o]/contributions[org_o][2]/avg_comp
	compositions[org_o] = [min_per,max_per,avg_per]
	print(f"{org_o} is {compositions[org_o]}")


fig, ax = plt.subplots()
ax.boxplot(compositions.values(),labels=raw_data.keys(),vert=False)
plt.show()
