## Cell Ranger snRNA-seq pipeline

Runs QC on raw FASTQs, builds a Cell Ranger-compatible Mmul_10 (macaque)
reference, and runs `cellranger count` for each library — submitting one
LSF job per sample/directory so work runs in parallel.

### Setup

```bash
cp config_qc.sh
# edit config.sh with your HPC username, PI data path
```

### Usage

```bash
# 0. QC raw FASTQs and aggregate results before mapping
./run_fastqc_multiqc.sh

```

### Output

- **QC:** `qc/fastqc/` holds per-file FastQC reports; `qc/multiqc/multiqc_report.html`
  is the aggregated summary — check this before spending compute on mapping.

