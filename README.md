# ChIP-Seq-Analysis-Pipline
Complete ChIP-seq analysis pipeline using FastQC, Bowtie2, SAMtools, MACS2, IGV, and MEME Suite for peak calling, visualization, and motif analysis.

This repository contains a complete ChIP-seq bioinformatics workflow for identifying genome-wide protein–DNA binding sites. The pipeline includes sequencing quality control, read alignment with Bowtie2, BAM processing with SAMtools, peak calling using MACS2, visualization in IGV, and motif discovery using MEME Suite and FIMO.

The workflow is designed for transcription factor ChIP-seq experiments comparing antibody-enriched samples against input/control samples.

## Table of contents 

- [1. Introduction](#1_._introduction)
2. Workflow Overview
3. Software Requirements
4. Installation
5. Data Download
6. Running the Pipeline
7. Peak Calling
8. Visualization in IGV
9. Motif Analysis
10. Results
11. References

# ChIP-seq Analysis Pipeline

## 1. Introduction

This repository contains a complete ChIP-seq bioinformatics workflow for identifying genome-wide protein–DNA binding sites using next-generation sequencing (NGS) data.

Chromatin Immunoprecipitation followed by sequencing (ChIP-seq) is widely used to study:
- Transcription factor binding sites
- Histone modifications
- Chromatin accessibility
- Epigenetic regulation

This workflow demonstrates a standard ChIP-seq analysis pipeline using:
- FastQC for quality control
- Bowtie2 for genome alignment
- SAMtools for BAM processing
- MACS2 for peak calling
- IGV for visualization
- MEME Suite/FIMO for motif analysis

The pipeline compares:
- ChIP sample (with antibody)
- Input/control sample (without antibody)

to identify statistically enriched DNA-binding regions (peaks).

---

# 2. Workflow Overview

## Pipeline Workflow

```text
FASTQ Files
     ↓
FastQC Quality Control
     ↓
Bowtie2 Alignment
     ↓
SAMtools BAM Processing
     ↓
MACS2 Peak Calling
     ↓
Peak Visualization (IGV)
     ↓
Motif Discovery (MEME/FIMO)
```

## Main Steps

1. Download raw sequencing data
2. Perform quality control
3. Align reads to reference genome
4. Convert SAM to sorted BAM
5. Call enriched peaks
6. Visualize peaks in IGV
7. Extract peak sequences
8. Discover transcription factor motifs

---

# 3. Software Requirements

## Operating System

- Ubuntu 20.04+ recommended

## Required Software

| Software | Purpose |
|---|---|
| FastQC | Read quality control |
| Bowtie2 | Read alignment |
| SAMtools | BAM processing |
| MACS2 | Peak calling |
| BEDTools | Genomic interval processing |
| deepTools | Coverage tracks |
| IGV | Genome visualization |
| MEME Suite | Motif discovery |

---

# 4. Installation

## Update Ubuntu

```bash
sudo apt update
```

## Install Required Tools

```bash
sudo apt install -y \
fastqc \
bowtie2 \
samtools \
bedtools \
sra-toolkit \
wget \
unzip \
python3-pip \
default-jre
```

## Install MACS2

```bash
pip3 install MACS2
```

## Install deepTools

```bash
sudo apt install -y deeptools
```

## Verify Installation

```bash
fastqc --version
bowtie2 --version
samtools --version
macs2 --version
```

---

# 5. Data Download

## Create Project Directory

```bash
mkdir -p chipseq_project/{raw_data,fastqc,index,bam,peaks,motifs,genome}
cd chipseq_project
```

## Download Reference Genome (hg19)

```bash
cd genome

wget https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz

gunzip hg19.fa.gz
```

## Build Bowtie2 Index

```bash
cd ../index

bowtie2-build ../genome/hg19.fa hg19
```

## Download SRA Data

Example:
- ChIP sample = SRR227524
- Control sample = SRR227650

```bash
cd ../raw_data

prefetch SRR227524
prefetch SRR227650
```

## Convert SRA to FASTQ

```bash
fasterq-dump SRR227524
fasterq-dump SRR227650
```

## Compress FASTQ Files

```bash
gzip *.fastq
```

---

# 6. Running the Pipeline

## Step 1: Quality Control

```bash
cd ../fastqc

fastqc ../raw_data/*.fastq.gz -o .
```

## Step 2: Align Reads with Bowtie2

```bash
cd ../bam

bowtie2 -x ../index/hg19 \
-U ../raw_data/SRR227524.fastq.gz \
-S chip.sam

bowtie2 -x ../index/hg19 \
-U ../raw_data/SRR227650.fastq.gz \
-S control.sam
```

## Step 3: Convert SAM to BAM

```bash
samtools view -bS chip.sam | samtools sort -o chip.sorted.bam

samtools view -bS control.sam | samtools sort -o control.sorted.bam
```

## Step 4: Index BAM Files

```bash
samtools index chip.sorted.bam

samtools index control.sorted.bam
```

## Step 5: Alignment Statistics

```bash
samtools flagstat chip.sorted.bam

samtools flagstat control.sorted.bam
```

---

# 7. Peak Calling

Peak calling identifies enriched genomic regions where proteins bind DNA.

## Run MACS2

```bash
cd ../peaks

macs2 callpeak \
-t ../bam/chip.sorted.bam \
-c ../bam/control.sorted.bam \
-f BAM \
-g hs \
-n chip_vs_control \
-q 0.01 \
--outdir .
```

## Important Output Files

| File | Description |
|---|---|
| narrowPeak | Peak coordinates |
| summits.bed | Peak summits |
| xls | Statistical information |
| bedGraph | Signal tracks |

## Count Peaks

```bash
wc -l chip_vs_control_peaks.narrowPeak
```

---

# 8. Visualization in IGV

## Create BigWig Coverage Files

```bash
cd ../bam

bamCoverage \
-b chip.sorted.bam \
-o chip.bw \
--binSize 10 \
--normalizeUsing RPKM

bamCoverage \
-b control.sorted.bam \
-o control.bw \
--binSize 10 \
--normalizeUsing RPKM
```

## Download IGV

```bash
cd ..

wget https://data.broadinstitute.org/igv/projects/downloads/2.17/IGV_Linux_2.17.4_WithJava.zip

unzip IGV_Linux_2.17.4_WithJava.zip
```

## Launch IGV

```bash
cd IGV_Linux_2.17.4

./igv.sh
```

## Load Files in IGV

Load:
- chip.sorted.bam
- control.sorted.bam
- chip.bw
- control.bw
- narrowPeak file

Select:
- Genome → Human hg19

---

# 9. Motif Analysis

Motif analysis identifies DNA sequence patterns enriched within peak regions.

## Extract Peak Sequences

```bash
cd ../motifs

bedtools getfasta \
-fi ../genome/hg19.fa \
-bed ../peaks/chip_vs_control_peaks.narrowPeak \
-fo chip_peaks.fa
```

## Run MEME

```bash
meme chip_peaks.fa \
-dna \
-oc meme_output \
-mod zoops \
-nmotifs 5 \
-minw 6 \
-maxw 20
```

## Run FIMO

```bash
fimo \
--oc fimo_output \
meme_output/meme.xml \
chip_peaks.fa
```

## Open Results

```bash
firefox meme_output/meme.html
```

---

# 10. Results

Expected outputs include:

- Quality control reports
- Sorted BAM alignment files
- Genome-wide peak coordinates
- Coverage tracks
- Peak summit regions
- Motif enrichment results

## Example Biological Interpretation

- Peaks represent potential transcription factor binding sites
- Strong enrichment indicates protein-DNA interaction
- Motifs suggest sequence-specific binding preferences

---

# 11. References

## ChIP-seq Guidelines

Bailey TL et al. (2013).  
Practical Guidelines for the Comprehensive Analysis of ChIP-seq Data.  
PLoS Computational Biology.  
https://doi.org/10.1371/journal.pcbi.1003326

## ENCODE Guidelines

Landt SG et al. (2012).  
ChIP-seq Guidelines and Practices of the ENCODE and modENCODE Consortia.  
Genome Research.  
https://genome.cshlp.org/content/22/9/1813

## Software Documentation

### Bowtie2
http://bowtie-bio.sourceforge.net/bowtie2

### SAMtools
http://www.htslib.org

### MACS2
https://github.com/macs3-project/MACS

### MEME Suite
https://meme-suite.org

### IGV
https://software.broadinstitute.org/software/igv

---

# Repository Structure

```text
chipseq-analysis-pipeline/
│
├── raw_data/
├── fastqc/
├── genome/
├── index/
├── bam/
├── peaks/
├── motifs/
├── scripts/
│
├── README.md
└── chipseq_pipeline.sh
```

## Author

Mahe Alam

## License

MIT License
