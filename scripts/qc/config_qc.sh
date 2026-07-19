#!/bin/bash


# HPC username (defaults to $USER if unset)
export HPC_USER="your-hpc-username"

# Path to PI's raw data directory on HPC cluster (fastq.gz)
export PI_DATA_DIR="/pi/raw_data/macaque"


# Working directory for project
export WORKDIR="$HOME/macaque_snRNAseq"