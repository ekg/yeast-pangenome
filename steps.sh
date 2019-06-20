#!/bin/bash

# get and compress the genomes
wget -i genomes.urls
ls *fa| while read file; do pigz $file; echo $file done; done

# prefix the sequence names with the strain name
ls *genome.fa.gz | while read file; do base=$(echo $file | cut -f 1 -d.); zcat $file | awk '/^>/ { print ">'$base'."substr($1, 2); } $0 !~ />/ {print toupper($0)}' | gzip >$(basename $file .fa.gz).prefix.fa.gz; done

# build the single reference file for seqwish
cat ordered_genomes | while read file; do zcat $file; done | pigz >Sc+Sp.pan.fa.gz

# (^^^todo: make seqwish read the genomes from a file list that provides sequence prefix / filename pairs, and avoids these preprocessing steps)

# run the pairwise alignment
time ./pan-minimap2 $(ls *genome.prefix* | grep -v Sarb | grep -v mt. ) | pigz >Sc+Sp.pan.paf.gz

# use fpa to filter short alignments
zcat Sc+Sp.pan.paf.gz | fpa -l 10000 | pigz >Sc+Sp.pan.fpal10k.paf.gz

# construct the graph from the alignments using seqwish
mkdir -p work # a work directory that's local, files created here will be deleted when seqwish completes
time seqwish -s Sc+Sp.pan.fa.gz -p Sc+Sp.pan.fpal10k.paf.gz -t 20 -b work/x -g Sc+Sp.pan.fpal10k.gfa

# transform the graph into odgi format and compact/order its id space
time odgi build -g Sc+Sp.pan.fpal10k.gfa -o - -p | odgi sort -i - -o Sc+Sp.pan.fpal10k.dg

# make a visualization
odgi viz -i Sc+Sp.pan.fpal10k.dg -x 4000 -y 800 -L 0 -X 1 -P 20 -R -o Sc+Sp.pan.fpal10k.dg.png

# basic statistics 
odgi stats -i Sc+Sp.pan.fpal10k.dg -S 
# the graph has about 20M of sequence

# build the graph with a weaker filter on the alignment length
zcat Sc+Sp.pan.paf.gz | fpa -l 2000 | pigz >Sc+Sp.pan.fpal2k.paf.gz
time seqwish -s Sc+Sp.pan.fa.gz -p Sc+Sp.pan.fpal2k.paf.gz -t 20 -b work/x -g Sc+Sp.pan.fpal2k.gfa

# transform the graph into odgi format and compact/order its id space
time odgi build -g Sc+Sp.pan.fpal2k.gfa -o - -p | odgi sort -i - -o Sc+Sp.pan.fpal2k.dg

# make a visualization
odgi viz -i Sc+Sp.pan.fpal2k.dg -x 4000 -y 800 -L 0 -X 1 -P 20 -R -o Sc+Sp.pan.fpal2k.dg.png

# basic statistics 
odgi stats -i Sc+Sp.pan.fpal2k.dg -S 
# the graph has about 15M of sequence

