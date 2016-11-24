#!/usr/bin/env Rscript

##
## Step 00. Common config
##
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  biomaRt,
  tidyverse,
  purrr,
  assertthat
)
ensembl_version = 'feb2014.archive.ensembl.org'

ensembl_connect <- function(ensembl_version = 'feb2014.archive.ensembl.org') {
  useMart(
    'ENSEMBL_MART_ENSEMBL',
    host = ensembl_version,
    dataset = 'hsapiens_gene_ensembl')
}


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
pacman::p_load(Rsamtools,
               GenomicRanges,
               rtracklayer,
               devtools)
devtools::install_github("kauralasoo/rasqual/rasqualTools")
library(rasqualTools)

path$gene_gc_content <- file.path(path$out_dir, 'gene_gc_content.csv')
count_matrix <- count_table %>%  as.data.frame %>% column_to_rownames('gene_id')


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

##
## Step 03. Compute exon unions
##
pacman::p_load(
  rtracklayer,
  VariantAnnotation
  )
path$gene_txdb <- file.path(path$out_dir, 'GRCh37.75.txdb')
path$uxonsbed <- file.path(path$out_dir, 'GRC37.75_exon_unions.bed')

if (!file.exists(path$gene_txdb)) {
  txdb <- makeTxDbFromBiomart(
    biomart = "ENSEMBL_MART_ENSEMBL",
    dataset = "hsapiens_gene_ensembl",
    host = ensembl_version)
  saveDb(txdb, path$gene_txdb)
} else {
  txdb <- loadDb(path$gene_txdb)
}
uxons <- reduce(exonsBy(txdb, "gene"))

get_exon_unions <- function(uxons) {
  df <- as.data.frame(uxons) %>% as_tibble() %>%
    dplyr::rename(gene_id = group_name, chr = seqnames,
                  exon_start = start, exon_end = end)
  udf <- df %>%
    dplyr::select(gene_id, chr, strand) %>%
    distinct() %>%
    mutate(strand = ifelse(strand == '+', 1, -1))
  exon_df <- df %>% group_by(gene_id) %>% summarize(
      exon_starts = paste(exon_start, collapse = ','),
      exon_ends = paste(exon_start, collapse = ',')
    )
  inner_join(udf, exon_df, by = 'gene_id') %>%
    mutate(strand = as.integer(strand), chr=as.character(chr))
}

path$gene_exon_union_df <- file.path(path$out_dir, 'gene_exon_union.tsv')
if (!file.exists(path$gene_exon_union_df)) {
  print("Computing gene exon union table (very time consuming ...")
  rasqual_df <- get_exon_unions(uxons)
  rasqual_df %>% write_delim(path$gene_exon_union_df, delim = '\t')
} else {
  rasqual_df <- read_delim(path$gene_exon_union_df, delim = '\t')
}

path$vcf_count <- 'output/all.counts.vcf'
path$snp_coords <- file.path(path$out_dir, 'snp_coords.tsv')

if (file.exists(path$snp_coords)) {
  snp_coords <- read_delim(path$snp_coords, delim = '\t')
} else {
  assert_that(file.exists(path$vcf_count))
  vcf <- readVcf(path$vcf_count)
  snp_coords <- as.data.frame(rowRanges(vcf)) %>%
    rownames_to_column(var = 'snp_id') %>%
    dplyr::select(chr = seqnames, pos = start, snp_id) %>%
    as_tibble
  snp_coords %>% write_delim(path$snp_coords, delim = '\t')
}

path$snp_counts <- file.path(path$out_dir, 'snp_counts.tsv')
if (file.exists(path$snp_counts)) {
  snp_counts <- read_delim(path$snp_counts, delim = '\t')
} else {
  snp_counts = countSnpsOverlapingExons(rasqual_df, snp_coords, cis_window = 5e5)
  snp_counts %>% write_delim(path$snp_counts)
}


