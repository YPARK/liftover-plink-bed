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

mart = ensembl_connect()

# the FDR column is currently just a p-value
df <- read_delim('output/gsTCC_time0.geneids_merged_eigenmt.txt',
                 delim = '\t')

# select a reasonably stringent p-value and see if we have anything interesting
sdf <- df %>% filter(pvalue < 0.01) %>% arrange(pvalue)

sdf$gene

gene_names <- getBM(attributes=c('ensembl_gene_id',
                   'hgnc_symbol',
                   'gene_biotype',
                   'chromosome_name',
                   'start_position',
                   'end_position'),
      filters = 'ensembl_gene_id',
      values =sdf$gene,
      mart = mart)

z <- gene_names %>% rename(gene=ensembl_gene_id) %>% inner_join(sdf) %>% filter(pvalue < 0.005)
cat(unique(z$hgnc_symbol), sep = '\n')
