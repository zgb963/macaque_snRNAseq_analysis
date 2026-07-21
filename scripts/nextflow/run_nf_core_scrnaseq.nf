#!/usr/bin/env nextflow

/*
 * run_cellranger_count.nf
 *
 * Full single-file Nextflow pipeline: FastQC -> Cell Ranger (mkgtf/mkref/count)
 * -> MultiQC, mirroring run_cellranger_count.sh plus QC aggregation. More efficient than running shell scripts!
 *
 * faster for hpc workflows, handels bsubs automatically
 * Usage:
 *   nextflow run run_nf_core_scrnaseq.nf -profile lsf
 */

nextflow.enable.dsl = 2

// ---------------------- User / cluster config ----------------------
params.hpc_user        = System.getenv('USER')
params.pi_data_dir     = "/pi/raw_data/macaque"
params.cellranger_bin  = "$HOME/yard/apps/cellranger-7.2.0"
params.workdir         = "$HOME/macaque_snRNAseq"
params.outdir          = "${params.workdir}/results"

// ---------------------- Reference genome files ----------------------
// Source: Ensembl release 113, Macaca_mulatta (Mmul_10)
params.genome_dir      = "${params.workdir}/ens_mmul10_genome_files"
params.gtf_raw         = "${params.genome_dir}/Macaca_mulatta.Mmul_10.113.gtf"
params.fasta           = "${params.genome_dir}/Macaca_mulatta.Mmul_10.dna.toplevel.fa"
params.reference_name  = "ens_mmul10_reference"

// GTF biotypes to keep (mirrors the --attribute flags in cellranger mkgtf)
def gtf_biotypes = [
    "protein_coding", "lncRNA", "antisense",
    "IG_LV_gene", "IG_V_gene", "IG_V_pseudogene",
    "IG_D_gene", "IG_J_gene", "IG_J_pseudogene",
    "IG_C_gene", "IG_C_pseudogene",
    "TR_V_gene", "TR_V_pseudogene", "TR_D_gene",
    "TR_J_gene", "TR_J_pseudogene", "TR_C_gene"
]

// ---------------------- Sample manifest ----------------------
// [sample_id, fastq_dir] — same as samples  array in the original script.
// NOTE: fastq_r1/fastq_r2 glob patterns assume standard 10x naming
// (<sample>_S*_L*_R1_001.fastq.gz / _R2_001.fastq.gz) inside fastq_dir.
def samples = [
    ["3-C_MI2_230608",      "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["4-D_MI2_230608",      "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["1-MI1_230808",        "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["2-MI1_230808",        "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["4-MI1_230808",        "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["5-MI1_230808",        "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["7-MI1_230808",        "${params.pi_data_dir}/Mmu_snRNA_run1_MI1_MI2_SNT_GLB_20230926_FASTQS_RE"],
    ["3-MI1_V1_230809",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["6-MI1_V1_230809",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["8-MI1_V1_230809",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["1-MI3_V1_231103",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["2-MI3_V1_231103",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["3-MI3_V1_231103",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["4-MI3_V1_231103",     "${params.pi_data_dir}/Mmu_snRNA_run3_MI1MI3_SNT_GLB_06042024_FASTQS"],
    ["5-MI3_V1_231103_CAT", "${params.pi_data_dir}/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"],
    ["6-MI3_V1_231103_CAT", "${params.pi_data_dir}/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"],
    ["7-MI3_V1_231103_CAT", "${params.pi_data_dir}/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"],
    ["8-MI3_V1_231103_CAT", "${params.pi_data_dir}/Mmu_snRNA_run6_run9_MI3_MI5_GLB_CAT_FASTQS"],
]

Channel
    .fromList(samples)
    .map { sample_id, fastq_dir -> tuple(sample_id, file(fastq_dir)) }
    .set { samples_ch }

// A second copy of the channel for FastQC's fastq-file globbing
Channel
    .fromList(samples)
    .map { sample_id, fastq_dir ->
        def r1 = file(fastq_dir).listFiles().findAll { it.name.contains("${sample_id}") && it.name.contains("_R1_") }
        def r2 = file(fastq_dir).listFiles().findAll { it.name.contains("${sample_id}") && it.name.contains("_R2_") }
        tuple(sample_id, r1 + r2)
    }
    .set { fastqc_input_ch }

// ---------------------- Processe (functions) ----------------------

process FASTQC {
    tag "$sample_id"
    executor 'lsf'
    queue 'short'
    cpus 4
    memory '8 GB'
    time '4h'
    publishDir "${params.outdir}/fastqc/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastqs)

    output:
    path "*_fastqc.{zip,html}", emit: fastqc_reports

    script:
    """
    fastqc -t 4 ${fastqs}
    """
}

process CELLRANGER_MKGTF {
    publishDir "${params.genome_dir}", mode: 'copy'

    input:
    path gtf_raw

    output:
    path "filtered_Macaca_mulatta.Mmul_10.113.gtf", emit: gtf_filtered

    script:
    def attr_flags = gtf_biotypes.collect { "--attribute=gene_biotype:${it}" }.join(" \\\n        ")
    """
    export PATH="\$PATH:${params.cellranger_bin}"
    cellranger mkgtf ${gtf_raw} filtered_Macaca_mulatta.Mmul_10.113.gtf \\
        ${attr_flags}
    """
}

process CELLRANGER_MKREF {
    // original bsub: -q long -R "rusage[mem=25G]" -R "span[hosts=1]" -W 96:00 -n 4
    executor 'lsf'
    queue 'long'
    cpus 4
    memory '25 GB'
    time '96h'
    publishDir "${params.workdir}", mode: 'copy'

    input:
    path fasta
    path gtf_filtered

    output:
    path "${params.reference_name}", emit: reference_dir

    script:
    """
    export PATH="\$PATH:${params.cellranger_bin}"
    cellranger mkref \\
        --genome=${params.reference_name} \\
        --fasta=${fasta} \\
        --genes=${gtf_filtered}
    """
}

process CELLRANGER_COUNT {
    // original bsub: -q long -W 96:00 -n 8 -R "rusage[mem=7.125GB] span[hosts=1]"
    // 8 cores x 7.125 GB = 57 GB per job (--localmem=57 below)
    tag "$sample_id"
    executor 'lsf'
    queue 'long'
    cpus 8
    memory '57 GB'
    time '96h'
    publishDir "${params.outdir}/cellranger_count", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq_dir)
    path reference_dir

    output:
    // Full outs/ dir: possorted_genome_bam.bam(+.bai), filtered/raw h5 matrices
    // (+ MEX dirs), metrics_summary.csv, web_summary.html, molecule_info.h5, etc.
    path "cellranger_count_${sample_id}_run_*/outs", emit: outs_dir
    path "cellranger_count_${sample_id}_run_*/outs/metrics_summary.csv", emit: metrics_csv

    script:
    def run_date = new Date().format('M_d_yy')
    """
    export PATH="\$PATH:${params.cellranger_bin}"
    cellranger count \\
        --id=cellranger_count_${sample_id}_run_${run_date} \\
        --transcriptome=${reference_dir} \\
        --fastqs=${fastq_dir} \\
        --sample=${sample_id} \\
        --jobmode=local --localcores=8 --localmem=57
    """
}

process MULTIQC {
    executor 'lsf'
    queue 'short'
    cpus 2
    memory '8 GB'
    time '2h'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path fastqc_reports, stageAs: 'fastqc/*'
    path cellranger_metrics, stageAs: 'cellranger/*'

    output:
    path "multiqc/multiqc_report.html"
    path "multiqc/multiqc_data"
    path "multiqc/multiqc_plots"

    script:
    """
    multiqc . -o multiqc -p
    """
}

// ---------------------- Workflow (like __main__ in py:) ----------------------
workflow {
    gtf_raw_ch = Channel.fromPath(params.gtf_raw)
    fasta_ch   = Channel.fromPath(params.fasta)

    FASTQC(fastqc_input_ch)

    CELLRANGER_MKGTF(gtf_raw_ch)
    CELLRANGER_MKREF(fasta_ch, CELLRANGER_MKGTF.out.gtf_filtered)
    CELLRANGER_COUNT(samples_ch, CELLRANGER_MKREF.out.reference_dir.first())

    MULTIQC(
        FASTQC.out.fastqc_reports.collect(),
        CELLRANGER_COUNT.out.metrics_csv.collect()
    )
}