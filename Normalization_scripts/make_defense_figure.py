#!/usr/bin/python

from statistics import mode
from sys import argv
import matplotlib.pyplot as plt
import re

file = argv[1]

list_o_bacteria = ["Bacillus",
				   "Bartonella",
				   "Bordetella",
				   "Borrelia",
				   "Brucella",
				   "Campylobacter",
				   "Chlamydia",
				   "Chylamydophila",
				   "Clostridium",
				   "Corynebacterium",
				   "Enterococcus",
				   "Escherichia",
				   "Francisella",
				   "Haemophilus",
				   "Helicobacter",
				   "Legionella",
				   "Leptospira",
				   "Listeria",
				   "Mycobacterium",
				   "Mycoplasma",
				   "Neisseria",
				   "Pseudomonas",
				   "Rickettsia",
				   "Salmonella",
				   "Shigella",
				   "Staphylococcus",
				   "Streptococcus",
				   "Treponema",
				   "Ureaplasma",
				   "Vibrio",
				   "Yersinia"]

raw_data = {}
with open(file,"r") as FILE:
	for line in FILE.readlines():
		if("Organism" not in line):
			name,taxid,rRNA = line.split("\t")
			name = name.split(" ")[0]
			name = name.replace("\"","")
			# name = name.split(" ")[0]
			rRNA = rRNA.split(";")
			rRNA = [int(i) for i in rRNA]
			if(abs(min(rRNA)-max(rRNA)) > 2 and max(rRNA) > 5 and name[0] == (name[0].upper())):
				raw_data[name] = rRNA

sorted_keys = [l for l in sorted(raw_data.keys())]
sorted_keys.reverse()
sorted_values = [raw_data[l] for l in sorted_keys]

fig, a1 = plt.subplots()
a1.boxplot(sorted_values,labels=sorted_keys,vert=False,whis=(0,100))
plt.xlim(0)
plt.show()
