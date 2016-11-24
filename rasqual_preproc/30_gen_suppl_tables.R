#!/usr/bin/env Rscript

##
## Step 00. Common config
##
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  purrr
)
# contains all the various paths used in this messy script. could be printed for easier debugging
path <- list()

path$out_dir <- '30_out'
dir.create(path$out_dir, showWarnings = FALSE)

##
## Step 01. Compute gene counts table
##

# `geno_bam_map` variable points to current mapping between genotype ID and bam file
path$geno_bam_map <- 'output/ASE_counts_at_time_0/sample_bam_map.tsv'
# Bam file count table
path$full_count_table <- 'input_data/counts.tsv'
# genotype id (subset of bam file counts) count table output
path$count_table <- file.path(path$out_dir, 'count_table.tsv')

sample_to_bamid <- read_delim(path$geno_bam_map, delim = '\t', col_names = c('sample', 'bam_path')) %>%
  transmute(sample, bam_id = basename(tools::file_path_sans_ext(bam_path)))

df <- read_delim(path$full_count_table, delim = '\t')

# Maps (complex) column names to (simple) sample names
bam_name <- tibble(bam_id = colnames(df)[2:ncol(df)])
name_mapping <- right_join(bam_name, sample_to_bamid)

rename_columns_with_bad_names <- function(df, src, dst) {
  # as.name quotes ugly names
  src_RID <- map(src, as.name)
  nm <- setNames(src_RID, name_mapping$sample)
  df %>% rename_(.dots = nm)
}

# select proper but wrongly named subset
df <- df %>% select(gene_id = 1, one_of(name_mapping$bam_id))
df <- rename_columns_with_bad_names(
  df, name_mapping$bam_id, name_mapping$sample)

df %>% write_delim(path$count_table, delim = '\t')
count_table <- df
cat("Wrote table to ", path$count_table, "\n")

##
## Step 02. Calculate Size Factors
##
pacman::p_load(biomaRt,
               Rsamtools,
               GenomicRanges,
               rtracklayer,
               devtools)
devtools::install_github("kauralasoo/rasqual/rasqualTools")
library(rasqualTools)

path$gene_gc_content <- file.path(path$out_dir, 'gene_gc_content.csv')
count_matrix <- count_table %>%  as.data.frame %>% column_to_rownames('gene_id')

ensembl_connect <- function(ensembl_version = 'feb2014.archive.ensembl.org') {
  useMart(
    'ENSEMBL_MART_ENSEMBL',
    host = ensembl_version,
    dataset = 'hsapiens_gene_ensembl')
}

download_geneid_and_gc <- function(mart) {
  getBM(attributes = c('ensembl_gene_id', 'percentage_gc_content'), mart = mart)
}

load_geneid_and_gc <- function(gid_gc_path) {
  if (file.exists(gid_gc_path)) {
    gid_gc <- read_csv(gid_gc_path)
  } else {
    mart <- ensembl_connect()
    gid_gc <- download_geneid_and_gc(mart)
    gid_gc %>% write_csv(gid_gc_path)
  }
  as_tibble(gid_gc) %>% dplyr::rename(gene_id = ensembl_gene_id)
}

gene_gc_content <- load_geneid_and_gc(path$gene_gc_content)

size_factors = rasqualCalculateSampleOffsets(count_matrix, gene_gc_content, gc_correct = TRUE)
saveRasqualMatrices(
  data_list = list(gsTC_T0 = size_factors),
  output_dir = path$out_dir,
  file_suffix = "size_factors_gc")
