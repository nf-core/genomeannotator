#!/usr/env python

import argparse
import sys,os
import re

class GFF3:
    
    def __init__(self,line):
        elements = line.split("\t")
        
        if not len(elements) == 9:
            sys.exit("GFF line contains unexpected number of elements...")
        

        self.seq_name,self.source,self.feature,self.start,self.stop,self.score,self.strand,self.phase,attrib = elements
        
        attributes = {}
        
        for a in attrib.split(";"):
            key,value = a.split("=")
            attributes[key] = value

        self.attributes = attributes

    def build_string(self):
        attribs = []
        for key in self.attributes:
            val = self.attributes[key]
            attribs.append(f"{key}={val}")

        astring = ";".join(attribs)
        return f"{self.seq_name}\t{self.source}\t{self.feature}\t{self.start}\t{self.stop}\t{self.score}\t{self.strand}\t{self.phase}\t{astring}\n"


parser = argparse.ArgumentParser(
	prog="augustus2gmod.py",
	description="A script to convert AUGUSTUS gene models into proper gff3"
)

parser.add_argument('--input', help='The file to read')
parser.add_argument('--output', help='The file to write')

args = parser.parse_args()

cds_counter     = None
transcript_id   = None
gene_id         = None

p = re.compile("^#.*")

o = open(args.output,"w+")

with open(args.input) as f:
    for line in f:
        if not p.match(line):

            gff = GFF3(line.rstrip())

            if gff.feature == "gene":
                gene_id = gff.attributes["ID"]
                o.write(gff.build_string())
            elif gff.feature == "transcript" or gff.feature == "mRNA":
                cds_counter = 0
                gff.feature = "mRNA"
                transcript_id = gff.attributes["ID"]
                o.write(gff.build_string())
            elif gff.feature == "CDS" or gff.feature == "cds":
                cds_counter += 1
                gff.attributes["ID"] = f"{transcript_id}.CDS-{cds_counter}"
                gff.attributes["Parent"] = transcript_id
                o.write(gff.build_string())
                gff.attributes["ID"] = f"{transcript_id}.EXON-{cds_counter}"
                gff.feature = "exon"
                gff.phase = "."
                o.write(gff.build_string())






