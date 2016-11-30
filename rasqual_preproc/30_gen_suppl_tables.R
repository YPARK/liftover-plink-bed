#!/usr/bin/env Rscript

##
## Step 00. Common config
## 

# rasqualTools requires at least 3.2.0
stopifnot(getRversion() >= "3.2.0")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  biomaRt,
  tidyverse,
  purrr,
  assertthat,
  ini,
  devtools
)
devtools::install_github("kauralasoo/rasqual/rasqualTools")
library(rasqualTools)

args = commandArgs(trailingOnly=TRUE)
config_file <- args[1]
assert_that(length(args) > 0, file.exists(config_file))

ensembl_version = 'feb2014.archive.ensembl.org'

ensembl_connect <- function(ensembl_version = 'feb2014.archive.ensembl.org') {
  useMart(
    'ENSEMBL_MART_ENSEMBL',
    host = ensembl_version,
    dataset = 'hsapiens_gene_ensembl')
}


# contains all the various paths used in this messy script. could be printed for easier debugging
path <- read.ini(config_file)

assert_that(dir.exists(path$TIMEPOINT$out_dir))

##
## Step 01. Compute gene counts table
##


sample_to_bamid <- read_delim(path$INPUT$geno_bam_map, delim = '\t', col_names = c('sample', 'bam_path')) %>%
  transmute(sample, bam_id = basename(tools::file_path_sans_ext(bam_path)))

df <- read_delim(path$INPUT$full_count_table, delim = '\t')

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

df %>% write_delim(path$TIMEPOINT$count_table, delim = '\t')
count_matrix <- df %>%  as.data.frame %>% column_to_rownames('gene_id')
saveRasqualMatrices(
  setNames(list(count_matrix), path$TIMEPOINT$name),
  path$TIMEPOINT$out_dir, file_suffix = "expression")
cat("Wrote table to ", path$TIMEPOINT$count_table, "\n")

##
## Step 02. Calculate Size Factors
##
pacman::p_load(Rsamtools,
               GenomicRanges,
               rtracklayer,
               devtools)
devtools::install_github("kauralasoo/rasqual/rasqualTools")
library(rasqualTools)



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

gene_gc_content <- load_geneid_and_gc(path$CACHE$gene_gc_content)

size_factors = rasqualCalculateSampleOffsets(count_matrix, gene_gc_content, gc_correct = TRUE)
saveRasqualMatrices(
  data_list = setNames(list(size_factors), path$TIMEPOINT$name),
  output_dir = path$TIMEPOINT$out_dir,
  file_suffix = "size_factors_gc")

#
## Step 03. Compute exon unions
##
pacman::p_load(
  rtracklayer,
  GenomicFeatures,
  VariantAnnotation
  )

if (!file.exists(path$CACHE$gene_txdb)) {
  txdb <- makeTxDbFromBiomart(
    biomart = "ENSEMBL_MART_ENSEMBL",
    dataset = "hsapiens_gene_ensembl",
    host = ensembl_version)
  saveDb(txdb, path$CACHE$gene_txdb)
} else {
  txdb <- AnnotationDbi::loadDb(path$CACHE$gene_txdb)
}

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

print("Computing gene exon union table)")
if (!file.exists(path$CACHE$gene_exon_union_df)) {
  uxons <- reduce(exonsBy(txdb, "gene"))
  rasqual_df <- get_exon_unions(uxons)
  rasqual_df %>% write_delim(path$CACHE$gene_exon_union_df, delim = '\t')
} else {
  rasqual_df <- read_delim(path$CACHE$gene_exon_union_df, delim = '\t',
                           col_types = 'ccicc'
                           )
}

##
## Step  04. Count SNPs per window
##


print("Computing SNP coordinates")
if (file.exists(path$CACHE$snp_coords)) {
  snp_coords <- read_delim(path$CACHE$snp_coords, delim = '\t',
                           col_types = 'cic')#,
} else {
  assert_that(file.exists(path$INPUT$vcf_file))
  # readVcf version on calculon insisted on an explicit genome version ...
  vcf <- readVcf(path$INPUT$vcf_file, genome='GRCh37')
  snp_coords <- as.data.frame(rowRanges(vcf)) %>%
    rownames_to_column(var = 'snp_id') %>%
    dplyr::select(chr = seqnames, pos = start, snp_id) %>%
    as_tibble
  snp_coords %>% write_delim(path$CACHE$snp_coords, delim = '\t')
}

print("Computing SNP counts")
if (file.exists(path$TIMEPOINT$snp_counts)) {
  snp_counts <- read_delim(path$TIMEPOINT$snp_counts, delim = '\t',
                           col_types = 'cciccddii')
} else {
  snp_counts = countSnpsOverlapingExons(rasqual_df, snp_coords, cis_window = path$INPUT$snp_cis_window)
  snp_counts %>% write_delim(path$TIMEPOINT$snp_counts, delim = '\t')
}

