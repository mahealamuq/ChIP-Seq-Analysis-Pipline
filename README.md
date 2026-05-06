# ChIP-Seq-Analysis-Pipline
Complete ChIP-seq analysis pipeline using FastQC, Bowtie2, SAMtools, MACS2, IGV, and MEME Suite for peak calling, visualization, and motif analysis.

This repository contains a complete ChIP-seq bioinformatics workflow for identifying genome-wide protein–DNA binding sites. The pipeline includes sequencing quality control, read alignment with Bowtie2, BAM processing with SAMtools, peak calling using MACS2, visualization in IGV, and motif discovery using MEME Suite and FIMO.

The workflow is designed for transcription factor ChIP-seq experiments comparing antibody-enriched samples against input/control samples.

## Table of contain 

1. Introduction
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

## Workflow

 FASTQ
 
 ↓
 
FastQC

 ↓
 
Bowtie2 Alignment

 ↓
 
SAMtools BAM Processing

 ↓
 
MACS2 Peak Calling

 ↓
 
IGV Visualization

 ↓
 
MEME/FIMO Motif Analysis
