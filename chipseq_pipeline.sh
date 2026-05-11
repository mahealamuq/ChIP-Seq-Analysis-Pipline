#!/bin/bash
set -e

# ==================================================
# Full ChIP-seq Analysis Pipeline
# FASTQ → FastQC → Bowtie2 → BAM → MACS2 → IGV → MEME
# ==================================================

PROJECT="chip_seq_data_analysis"
ENV_NAME="chipseq"

CHIP="SRR227524"
CONTROL="SRR227650"
THREADS=4

echo "Creating project folders..."
mkdir -p $PROJECT/{raw_data,fastqc,index,bam,peaks,motifs,genome}
cd $PROJECT

echo "Installing basic Ubuntu packages..."
sudo apt update
sudo apt install -y wget unzip curl default-jre sra-toolkit python3-pip firefox

echo "Installing Miniconda if missing..."
if [ ! -d "$HOME/miniconda3" ]; then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
fi

echo "Loading Conda..."
source $HOME/miniconda3/etc/profile.d/conda.sh

echo "Creating Conda environment..."
if ! conda env list | grep -q "$ENV_NAME"; then
    conda create -n $ENV_NAME python=3.10 -y
fi

conda activate $ENV_NAME

echo "Installing bioinformatics tools..."
conda install -c bioconda -c conda-forge -y \
fastqc \
bowtie2 \
samtools \
bedtools \
deeptools \
meme

echo "Installing MACS2 with pip..."
pip3 install MACS2

echo "Checking software versions..."
python --version
fastqc --version
bowtie2 --version
samtools --version
bedtools --version
bamCoverage --version
macs2 --version
meme -version

echo "Downloading hg19 reference genome..."
cd genome

if [ ! -f hg19.fa ]; then
    wget https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
    gunzip hg19.fa.gz
fi

cd ..

echo "Building Bowtie2 index..."
cd index

if [ ! -f hg19.1.bt2 ]; then
    bowtie2-build ../genome/hg19.fa hg19
fi

cd ..

echo "Downloading ChIP and control SRA data..."
cd raw_data

prefetch $CHIP
prefetch $CONTROL

echo "Converting SRA to FASTQ..."
if [ ! -f ${CHIP}.fastq.gz ]; then
    fasterq-dump $CHIP
    gzip ${CHIP}.fastq
fi

if [ ! -f ${CONTROL}.fastq.gz ]; then
    fasterq-dump $CONTROL
    gzip ${CONTROL}.fastq
fi

cd ..

echo "Running FastQC..."
fastqc raw_data/*.fastq.gz -o fastqc

echo "Aligning ChIP sample..."
bowtie2 \
-p $THREADS \
-x index/hg19 \
-U raw_data/${CHIP}.fastq.gz \
| samtools view -bS - \
| samtools sort -o bam/chip.sorted.bam

echo "Aligning control sample..."
bowtie2 \
-p $THREADS \
-x index/hg19 \
-U raw_data/${CONTROL}.fastq.gz \
| samtools view -bS - \
| samtools sort -o bam/control.sorted.bam

echo "Indexing BAM files..."
samtools index bam/chip.sorted.bam
samtools index bam/control.sorted.bam

echo "Generating alignment statistics..."
samtools flagstat bam/chip.sorted.bam > bam/chip.flagstat.txt
samtools flagstat bam/control.sorted.bam > bam/control.flagstat.txt

echo "Running MACS2 peak calling..."
macs2 callpeak \
-t bam/chip.sorted.bam \
-c bam/control.sorted.bam \
-f BAM \
-g hs \
-n chip_vs_control \
-q 0.01 \
--outdir peaks

echo "Checking peak output..."
head peaks/chip_vs_control_peaks.narrowPeak
wc -l peaks/chip_vs_control_peaks.narrowPeak

echo "Creating BigWig files for IGV..."
bamCoverage \
-b bam/chip.sorted.bam \
-o bam/chip.bw \
--binSize 10 \
--normalizeUsing RPKM

bamCoverage \
-b bam/control.sorted.bam \
-o bam/control.bw \
--binSize 10 \
--normalizeUsing RPKM

echo "Extracting peak sequences for motif analysis..."
bedtools getfasta \
-fi genome/hg19.fa \
-bed peaks/chip_vs_control_peaks.narrowPeak \
-fo motifs/chip_peaks.fa

echo "Running MEME motif analysis..."
cd motifs

meme chip_peaks.fa \
-dna \
-oc meme_output \
-mod zoops \
-nmotifs 5 \
-minw 6 \
-maxw 20

cd ..

echo "Downloading IGV..."
if [ ! -d IGV_Linux_2.17.4 ]; then
    wget https://data.broadinstitute.org/igv/projects/downloads/2.17/IGV_Linux_2.17.4_WithJava.zip
    unzip IGV_Linux_2.17.4_WithJava.zip
fi

echo "Opening FastQC and MEME reports..."
firefox fastqc/*.html motifs/meme_output/meme.html &

echo "======================================"
echo "Pipeline completed successfully!"
echo "======================================"
echo ""
echo "Main output files:"
echo "FastQC reports: fastqc/*.html"
echo "ChIP BAM: bam/chip.sorted.bam"
echo "Control BAM: bam/control.sorted.bam"
echo "ChIP BigWig: bam/chip.bw"
echo "Control BigWig: bam/control.bw"
echo "Peak file: peaks/chip_vs_control_peaks.narrowPeak"
echo "Peak sequences: motifs/chip_peaks.fa"
echo "MEME report: motifs/meme_output/meme.html"
echo ""
echo "To open IGV:"
echo "cd IGV_Linux_2.17.4"
echo "./igv.sh"
echo ""
echo "Load these files in IGV:"
echo "bam/chip.sorted.bam"
echo "bam/control.sorted.bam"
echo "bam/chip.bw"
echo "bam/control.bw"
echo "peaks/chip_vs_control_peaks.narrowPeak"
