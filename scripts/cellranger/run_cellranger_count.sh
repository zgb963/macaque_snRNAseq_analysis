#!/bin/bash
set -euo pipefail

# =============================================================================
# run_cellranger_count.sh
#
# Builds a Cell Ranger-compatible macaque (Mmul_10) reference genome and runs
# `cellranger count` for each snRNA-seq library, submitting one LSF job per
# sample so libraries process in parallel on HPC cluster.
#
# Usage:
#   ./run_cellranger_count.sh mkgtf      # filter the GTF
#   ./run_cellranger_count.sh mkref      # build the reference (submit as its own job)
#   ./run_cellranger_count.sh count      # submit one cellranger count job per sample
# =============================================================================

# --- User / cluster config (edit environment) ---------------------
# Loads config.sh if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/config.sh"
fi

HPC_USER="${HPC_USER:-$USER}"
PI_DATA_DIR="${PI_DATA_DIR:-/pi/raw_data/macaque}"
CELLRANGER_BIN="${CELLRANGER_BIN:-$HOME/yard/apps/cellranger-7.2.0}"
WORKDIR="${WORKDIR:-$HOME/macaque_snRNAseq}"
LOG_DIR="$WORKDIR/cellranger_run_logs"

export PATH="$PATH:$CELLRANGER_BIN"

# --- Reference genome files ---------------------------------------------
# Source: Ensembl release 113, Macaca_mulatta (Mmul_10)
# GTF (no "chr" prefix, full genome):
#   https://ftp.ensembl.org/pub/release-113/gtf/macaca_mulatta/Macaca_mulatta.Mmul_10.113.gtf.gz
# FASTA (unmasked, toplevel/primary assembly — recommended by 10x for
# complete genome coverage without alt scaffolds/contigs):
#   https://ftp.ensembl.org/pub/release-113/fasta/macaca_mulatta/dna/Macaca_mulatta.Mmul_10.dna.toplevel.fa.gz
# 10x reference-building guide:
#   https://www.10xgenomics.com/support/software/cell-ranger/latest/tutorials/cr-tutorial-mr#macaque_6.0.0
GENOME_DIR="$WORKDIR/ens_mmul10_genome_files"
GTF_RAW="$GENOME_DIR/Macaca_mulatta.Mmul_10.113.gtf"
GTF_FILTERED="$GENOME_DIR/filtered_Macaca_mulatta.Mmul_10.113.gtf"
FASTA="$GENOME_DIR/Macaca_mulatta.Mmul_10.dna.toplevel.fa"
REFERENCE_NAME="ens_mmul10_reference"

# --- Sample manifest -------------------------------------------------------
# One entry per library: "sample_id|fastq_dir"
# (sample_id must match the --sample flag cellranger expects — no BaseSpace
# S-number, and any "_CAT" suffix used to indicate concatenated/re-run lanes.)
SAMPLES=(
  "3-C_MI2_230608|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "4-D_MI2_230608|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "1-MI1_230808|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "2-MI1_230808|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "4-MI1_230808|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "5-MI1_230808|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "7-MI1_230808|$PI_DATA_DIR/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"
  "3-MI1_V1_230809|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "6-MI1_V1_230809|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "8-MI1_V1_230809|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "1-MI3_V1_231103|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "2-MI3_V1_231103|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "3-MI3_V1_231103|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "4-MI3_V1_231103|$PI_DATA_DIR/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"
  "5-MI3_V1_231103_CAT|$PI_DATA_DIR/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"
  "6-MI3_V1_231103_CAT|$PI_DATA_DIR/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"
  "7-MI3_V1_231103_CAT|$PI_DATA_DIR/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"
  "8-MI3_V1_231103_CAT|$PI_DATA_DIR/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"
)

# --- Step 1: filter GTF ------------------------------------------------
# Removes non-polyA transcripts that overlap protein-coding gene models,
# keeping biotypes cellranger expects.
step_mkgtf() {
  cellranger mkgtf "$GTF_RAW" "$GTF_FILTERED" \
    --attribute=gene_biotype:protein_coding \
    --attribute=gene_biotype:lncRNA \
    --attribute=gene_biotype:antisense \
    --attribute=gene_biotype:IG_LV_gene \
    --attribute=gene_biotype:IG_V_gene \
    --attribute=gene_biotype:IG_V_pseudogene \
    --attribute=gene_biotype:IG_D_gene \
    --attribute=gene_biotype:IG_J_gene \
    --attribute=gene_biotype:IG_J_pseudogene \
    --attribute=gene_biotype:IG_C_gene \
    --attribute=gene_biotype:IG_C_pseudogene \
    --attribute=gene_biotype:TR_V_gene \
    --attribute=gene_biotype:TR_V_pseudogene \
    --attribute=gene_biotype:TR_D_gene \
    --attribute=gene_biotype:TR_J_gene \
    --attribute=gene_biotype:TR_J_pseudogene \
    --attribute=gene_biotype:TR_C_gene
}

# --- Step 2: build the reference ---------------------------------------
# Run as its own LSF job (takes ~40 min):
#   bsub -q long -R "rusage[mem=25G]" -R "span[hosts=1]" -W 96:00 -n 4 \
#     -o "$LOG_DIR/mkref.%J.out" -e "$LOG_DIR/mkref.%J.err" \
#     ./run_cellranger_count.sh mkref
step_mkref() {
  cd "$WORKDIR"
  cellranger mkref \
    --genome="$REFERENCE_NAME" \
    --fasta="$FASTA" \
    --genes="$GTF_FILTERED"
}

# --- Step 3: run cellranger count per sample ----------------------------
# Submits one LSF job per library so all samples run in parallel
# 8 cores x 7.125 GB = 57 GB per job.
step_count() {
  mkdir -p "$LOG_DIR"
  cd "$WORKDIR"
  local run_date
  run_date="$(date +%-m_%-d_%y)"

  for entry in "${SAMPLES[@]}"; do
    local sample="${entry%%|*}"
    local fastq_dir="${entry##*|}"
    local run_id="cellranger_count_${sample}_run_${run_date}"

    bsub -q long -W 96:00 -n 8 -R "rusage[mem=7.125GB] span[hosts=1]" \
      -o "$LOG_DIR/cellranger_count_${sample}.%J.log" \
      cellranger count \
        --id="$run_id" \
        --transcriptome="$REFERENCE_NAME" \
        --fastqs="$fastq_dir" \
        --sample="$sample" \
        --jobmode=local --localcores=8 --localmem=57
  done
}

# --- Entry point -------------------------------------------------------
case "${1:-}" in
  mkgtf) step_mkgtf ;;
  mkref) step_mkref ;;
  count) step_count ;;
  *)
    echo "Usage: $0 {mkgtf|mkref|count}" >&2
    exit 1
    ;;
esac
