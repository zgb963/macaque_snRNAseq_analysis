## Introduction

Neuronal activity-dependent gene programs include modulators of neuronal activity and plasticity, with effects on behavior and learning. Mutations in activity dependent gene programs associated with neurological diseases such as autism, schizophrenia, bipolar, etc. Rodent models were essential for understanding neuronal activity-dependent gene expression, yet primates have evolved unique cellular and molecular features that may be critical for understanding human neurodevelopmental disorders. Lab previously discovered that activity dependent gene programs differ between rodents and primates, and found significant enrichment of autism-associated genes inside activity-regulated promoters of stem cell derived neurons. This suggests that autism risk variants may disrupt primate activity dependent pathways not visible in rodent studies.

Lab generated snRNAseq data from primary visual cortex (V1) of Rhesus macaque (Macaca mulatta) after Monocular inactivation (MI).This procedure involves blinding macaques in one eye with a TTX injection (a neurotoxin that pauses neural activity). Then RNA situ hybridization (FISH) is done in primary visual cortex. Probing for specific activity-dependent genes resulted in alternating active and inactive ocular dominance columns. 24 hours after monocular inactivation, layer 4C neurons are probed for OSTN and LINC00473. Activity regulated transcripts OSTN & FSTL1 or OSTN & EGR1 are enriched in active columns [Ataman et al. 2016](https://pubmed.ncbi.nlm.nih.gov/27830782/) 



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

---

## Methods
## Methods

1. **Alignment & quantification**
   Ran Cell Ranger `count` using ENSEMBL Rhemac10 GTF (no chr) `Macaca_mulatta.Mmul_10.113.gtf`
    & FASTA (unmasked) `Macaca_mulatta.Mmul_10.dna.toplevel.fa.gz`
    
2. **Downstream analysis in R**
   Performed downstream processing and QC in R (note: some steps are redundant with Cell Ranger's built-in filtering).

   1. **Ambient RNA correction — SoupX**
      Identified and corrected for ambient RNA contamination.

   2. **Damaged nuclei filtering — MiQC**
      Identified and removed damaged/low-quality nuclei.

   3. **Empty droplet filtering — DropletQC**
      Identified and removed empty droplets.

   4. **Standard Seurat Analysis**
      Analyzed snRNA-seq data (normalization, dimensionality reduction, clustering).

   5. **Doublet detection — DoubletFinder**
      Identified and removed doublets.

3. **Combine Samples**
   Combined all libraries into a single Seurat object and generated combined UMAP.

4. **Feature visualization**
   Created feature  UMAP & violin plots for marker genes of interest.

5.  **Integration with similar snRNAseq dataset**
    Integrate data with [Wei et al. 2022](https://www.nature.com/articles/s41467-022-34590-1)

6.  **Cell type annotation**
    Finalize cell type identities for each cluster.

7.  **Cell state discovery**
    Identify cell states (active vs. inactive) within cell types. Software tested below.
    1.  **NEUROeSTIMator**
        Deep learning neural network model to identify cell activity.
    2.  **Consensus NMF (cNMF)**
        cNMF is a pipeline for inferring gene expression programs from scRNA-seq.
    3.  **Manual labeling**
        Manually label cells if have more than ~3 read mapped to activity dependent gene.
    
8.  **Cross-dataset comparison**
    Compared results to other published macaque snRNA-seq datasets.


---

## Results

> 🔬 Analysis ongoing

---

## Helpful Links & References

- [Chromium Next GEM Single Cell 3ʹ Reagent Kits v3.1 (Dual Index)](https://cdn.10xgenomics.com/image/upload/v1668017706/support-documents/CG000315_ChromiumNextGEMSingleCell3-_GeneExpression_v3.1_DualIndex__RevE.pdf)
- [Cell Ranger count Pipeline CLI](https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/running-pipelines/cr-gex-count)
- [SoupX](https://pubmed.ncbi.nlm.nih.gov/33367645/)
- [MiQC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8415599/)
- [DropletQC](https://pubmed.ncbi.nlm.nih.gov/34857027/)
- [DoubletFinder](https://pubmed.ncbi.nlm.nih.gov/30954475/)
- [Doublet Detection Benchmarking](https://pubmed.ncbi.nlm.nih.gov/33338399/)
- [Seurat Clustering](https://satijalab.org/seurat/articles/pbmc3k_tutorial)
- [Merge Seurat Objects](https://satijalab.org/seurat/articles/essential_commands#subsetting-and-merging)
- [Mapping and annotating query datasets](https://satijalab.org/seurat/articles/integration_mapping.html)
- [NEUROeSTIMator](https://www.nature.com/articles/s41467-023-44503-5)
- [cnmf](https://www.nature.com/articles/s41467-023-44503-5)



















