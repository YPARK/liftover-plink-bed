#!/usr/bin/env Rscript
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  purrr,
  assertthat
)

read_chromosome_for_exps <- function(base_dir, experiments, filename) {
  exps <- list()
  for (exp in experiments) {
    fp <- file.path(base_dir, exp, filename)
    exps[[exp]] <- read_delim(fp, delim = '\t')
  }
  exps
}

base_dir <- './10_ichip_lldeep/individual/'
experiments <- c('dunno', 'sollid', 'konig')
filenames <- list.files(file.path(base_dir, experiments[1]))
common_dir <- file.path('15_common_intensities')
dir.create(common_dir, showWarnings = FALSE)

for (chromfile in filenames) {
  dfs <- read_chromosome_for_exps(base_dir, experiments, chromfile)
  common_df <- reduce(dfs, inner_join)

  assert_that(
    sum(map_dbl(dfs, ~ ncol(.x) - 3)) ==
    ncol(common_df) - 3)
  assert_that(length(unique(map_dbl(dfs, nrow))) == 1)
  assert_that(nrow(common_df) == nrow(dfs[[1]]))
  common_df %>% write_delim(file.path(common_dir, chromfile), delim = '\t')
}
