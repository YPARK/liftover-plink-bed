#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
cat("Supplied(", length(args), ") arguments where: ", args, "\n")
if (length(args) != 3) {
  print("A simple script that reads a two column mapping and a possibly large count table.")
  print("Outputs a possibly smaller and renamed count table")
  stop("invoke with: ./gene_counts_per_sample.R --args <sample_to_bam.map> <counts.tsv> <output_counts.tsv>")
}

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  purrr
)

map_path <- args[1]
count_table_path <- args[2]
output_table_path <- args[3]

sample_to_bamid <- read_delim(map_path, delim = '\t', col_names = c('sample', 'bam_path')) %>%
  transmute(sample, bam_id = basename(tools::file_path_sans_ext(bam_path)))

df <- read_delim(count_table_path, delim = '\t')

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

df %>% write_delim(output_table_path, delim = '\t')
cat("Wrote table to ", output_table_path, "\n")
