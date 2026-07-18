## Cell Ranger snRNA-seq pipeline

Builds a Cell Ranger-compatible Mmul_10 (macaque) reference and runs
`cellranger count` for each library, submitting one LSF job per sample.

### Setup

```bash
cp config.example.sh config.sh
# edit config.sh with your HPC username, PI data path, and cellranger install path
```

`config.sh` is gitignored — your real paths never get committed.

### Reference genome

Reference files are pulled from Ensembl release 113 and are not stored in
this repo (see `.gitignore`). Download them into `$WORKDIR/ens_mmul10_genome_files/`:

- GTF: https://ftp.ensembl.org/pub/release-113/gtf/macaca_mulatta/Macaca_mulatta.Mmul_10.113.gtf.gz
- FASTA (toplevel/unmasked): https://ftp.ensembl.org/pub/release-113/fasta/macaca_mulatta/dna/Macaca_mulatta.Mmul_10.dna.toplevel.fa.gz

### Usage

```bash
# 1. Filter the GTF to cellranger-compatible biotypes
./run_cellranger_count.sh mkgtf

# 2. Build the reference (submit as its own LSF job — takes ~40 min)
bsub -q long -R "rusage[mem=25G]" -R "span[hosts=1]" -W 96:00 -n 4 \
  -o cellranger_run_logs/mkref.%J.out -e cellranger_run_logs/mkref.%J.err \
  ./run_cellranger_count.sh mkref

# 3. Submit one cellranger count job per sample (edit the SAMPLES array
#    in the script to match your libraries)
./run_cellranger_count.sh count
```

### Output

Each sample produces a `cellranger_count_<sample>_run_<date>/outs/` folder
containing the standard Cell Ranger outputs (filtered/raw matrices,
`web_summary.html`, `metrics_summary.csv`, `possorted_genome_bam.bam`,
etc.) — ready for downstream analysis in R/Seurat.
