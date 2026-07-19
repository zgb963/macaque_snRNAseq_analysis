#!/bin/bash
set -euo pipefail

# =============================================================================
# run_fastqc_multiqc.sh
#
# Runs FastQC on all raw FASTQ files for each library, waits for every
# FastQC job to finish, then aggregates all reports into a single
# MultiQC summary. QC checkpoint on raw input BEFORE running
# run_cellranger_count.sh (mkgtf/mkref/count)
#
# Usage:
#   ./run_fastqc_multiqc.sh
# =============================================================================

# --- User / cluster config ---------------------
# Loads config.sh if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/config.sh"
fi

HPC_USER="${HPC_USER:-$USER}"
PI_DATA_DIR="${PI_DATA_DIR:-/pi/raw_data/macaque}"
WORKDIR="${WORKDIR:-$HOME/macaque_snRNAseq}"
QC_DIR="$WORKDIR/qc"
LOG_DIR="$QC_DIR/logs"
FASTQC_OUT="$QC_DIR/fastqc"
MULTIQC_OUT="$QC_DIR/multiqc"

# --- Raw FASTQ directories --------------------------------------------------
# Reuses the same set of run directories referenced in the SAMPLES manifest
# in run_cellranger_count.sh. Listed once here (deduplicated) since FastQC
# runs per-directory rather than per-sample.
FASTQ_DIRS=(
  "$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "$PI_DATA_DIR/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"
)

# --- Step 1: FastQC ----------------------------------------------------
# Submits one LSF job per FASTQ directory
step_fastqc() {
  mkdir -p "$LOG_DIR" "$FASTQC_OUT"

  for fastq_dir in "${FASTQ_DIRS[@]}"; do
    local dir_name
    dir_name="$(basename "$fastq_dir")"

    bsub -q short -W 4:00 -n 4 -R "rusage[mem=4GB] span[hosts=1]" \
      -o "$LOG_DIR/fastqc_${dir_name}.%J.log" \
      fastqc "$fastq_dir"/*.fastq.gz \
        --outdir "$FASTQC_OUT" \
        --threads 4 &
  done

  wait
}

# --- Step 2: MultiQC ----------------------------------------------------
# Aggregate FastQC reports in $FASTQC_OUT into one summary report
step_multiqc() {
  mkdir -p "$MULTIQC_OUT"
  multiqc "$FASTQC_OUT" --outdir "$MULTIQC_OUT"
}

# --- Run ------------------------------------------------------------------
# run both steps
step_fastqc
step_multiqc


