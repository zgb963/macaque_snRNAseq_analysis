## Introduction

Neuronal activity turns on distinct gene programs in each brain cell type,
and this activity-regulated gene expression is essential for healthy brain
development, function, and plasticity. Genes central to this program —
transcription factors, chromatin regulators, ion channels — are linked to
severe neurodevelopmental disorders, and GWAS have repeatedly tied
activity-dependent gene networks to autism, schizophrenia, depression,
bipolar disorder, and cognitive traits. The lab previously found
significant enrichment of autism-associated genes among activity-regulated
genes in stem cell-derived neurons, and of autism risk within their
activity-regulated promoters (LDSC).

These programs are well characterized in the rodent brain, but almost
nothing is known about them in the primate or human brain in vivo. Our
cell culture studies have identified dozens of primate-specific
activity-regulated genes, suggesting primate-specific pathways for
neuronal plasticity — but until now, there has been no way to study these
programs directly in the living primate brain.

The lab compares activity-dependent transcription and epigenomics in human
neurons in vitro and non-human primates in vivo, revealing both
primate-specific and repurposed conserved genes. One example is *OSTN*, a
secreted peptide the lab PI identified as activity-induced in human and
macaque — but not mouse or rat — brain, driven by primate-specific
enhancer changes and shown to regulate dendritic outgrowth in developing
human neurons. We continue to study OSTN's regulatory evolution and its
controlling transcription factors, SATB2 and MEF2C.

### How single cell RNAseq (scRNAseq) differs from single nucleus RNAseq (snRNA-seq)

While scRNA-seq and snRNA-seq both aim to quantify gene expression at single-cell resolution, they differ in starting material and tissue compatibility:

| Feature | scRNA-seq | snRNA-seq |
|---|---|---|
| Starting material | Whole dissociated cells | Isolated nuclei |
| Tissue compatibility | ✅ Fresh, easily dissociated tissue | ✅ Frozen, archived, or hard-to-dissociate tissue |
| Captured RNA | Cytoplasmic + nuclear mRNA | Nuclear pre-mRNA/nascent transcripts |
| Dissociation stress | ⚠️ Higher — can induce stress-response artifacts | ✅ Lower — avoids enzymatic cell dissociation |
| Cell type recovery | ❌ Biased against fragile/large cells (e.g., neurons) | ✅ More even recovery across cell types |
| Reference/counting | Standard exon-focused alignment | Requires intron-inclusive reference (e.g., `--include-introns`) |

Gene expression counts in snRNA-seq represent the **number of RNA transcripts detected per gene per nucleus**, including a higher proportion of intronic/unspliced reads reflecting nuclear RNA capture. These counts are used for:
- Cell type characterization
- Comparison against frozen/archival tissue cohorts
- Quality control and filtering

> ⚠️ **Filtering note:** Nuclei with very low total gene expression counts or high intronic read fractions may reflect empty droplets, debris, or poor nuclei integrity. Filtering is essential for reliable downstream analysis but should be applied carefully. *(Thresholds: TBD)*




## Goals

- [ ] Identify cell types in macaque V1
- [ ] Identify activated vs. inactivated transcriptional profile for each neuronal cell type
- [ ] Discover novel primate neuronal activity-regulated gene expression programs at cell-type resolution

This repository contains the analysis pipeline examining activity-dependent gene programs in the primate brain.