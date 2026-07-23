## Introduction

Neuronal activity-dependent gene programs include modulators of neuronal activity and plasticity, with effects on behavior and learning. Mutations in activity dependent gene programs associated with neurological diseases such as autism, schizophrenia, bipolar, etc. Rodent models were essential for understanding neuronal activity-dependent gene expression, yet primates have evolved unique cellular and molecular features that may be critical for understanding human neurodevelopmental disorders. Lab previously discovered that activity dependent gene programs differ between rodents and primates, and found significant enrichment of autism-associated genes inside activity-regulated promoters of stem cell derived neurons. This suggests that autism risk variants may disrupt primate activity dependent pathways not visible in rodent studies.

Lab generated snRNAseq data from primary visual cortex (V1) of Rhesus macaque (Macaca mulatta) after Monocular inactivation (MI).This procedure involves blinding macaques in one eye with a TTX injection (a neurotoxin that pauses neural activity). Then RNA situ hybridization (FISH) is done in primary visual cortex. Probing for specific activity-dependent genes resulted in alternating active and inactive ocular dominance columns. 24 hours after monocular inactivation, layer 4C neurons are probed for OSTN and LINC00473. Activity regulated transcripts OSTN & FSTL1 or OSTN & EGR1 are enriched in active columns [citation]



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

---

## Data

### Sample overview

18 libraries/biological replicates generated using 10x Genomics Single Cell 3' Kit (Dual Index) and sequenced using Illumina NextSeq 2000 across three animals from monocular inactivation (MI) experiments:

- **8 replicates** from MI1
- **2 replicates** from MI2
- **8 replicates** from MI3

**Conditions:**
| Animal ID | Condition |
|---|---|
| MI1 | Monocular inactivation, animal 1 |
| MI2 | Monocular inactivation, animal 2 |
| MI3 | Monocular inactivation, animal 3 |


### Libraries Sequenced

| Experiment | Sequencing Run | Sample ID |
|---|---|---|
| MI2 | 1 | 3-C_MI2_230608 |
| MI2 | 1 | 4-D_MI2_230608 |
| MI1 | 1 | 1-MI1_230808 |
| MI1 | 1 | 2-MI1_230808 |
| MI1 | 1 | 4-MI1_230808 |
| MI1 | 1 | 5-MI1_230808 |
| MI1 | 1 | 7-MI1_230808 |
| MI1 | 3 | 3-MI1_V1_230809 |
| MI1 | 3 | 6-MI1_V1_230809 |
| MI1 | 3 | 8-MI1_V1_230809 |
| MI3 | 3 | 1-MI3_V1_231103 |
| MI3 | 3 | 2-MI3_V1_231103 |
| MI3 | 3 | 3-MI3_V1_231103 |
| MI3 | 3 | 4-MI3_V1_231103 |
| MI3 | 6 & 9 | 5-MI3_V1_231103 |
| MI3 | 6 & 9 | 6-MI3_V1_231103 |
| MI3 | 6 & 9 | 7-MI3_V1_231103 |
| MI3 | 6 & 9 | 8-MI3_V1_231103 |

> **Note:** Combined gene expression (GEX) library 3 FASTQ files were pooled from Run 6 and Run 9.

---


## Goals

- [ ] Identify cell types in macaque V1
- [ ] Identify activated vs. inactivated transcriptional profile for each neuronal cell type
- [ ] Discover novel primate neuronal activity-regulated gene expression programs at cell-type resolution

This repository contains preliminary analysis pipelines examining activity-dependent gene programs in the primate brain.