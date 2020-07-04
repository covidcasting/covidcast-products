#!/usr/bin/env Rscript

library(rslurm)

library(readr)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(assertthat)
library(purrr, warn.conflicts = FALSE)
library(glue,  warn.conflicts = FALSE)
library(stringr)

sjob    <- readRDS('sjob.RDS')
d       <- tibble::as_tibble(get_slurm_out(sjob, outtype = 'table'))

result <- select_at(d, c('group_name', 'summary')) %>% unnest(summary)
result <- rename(result, state = group_name)

readr::write_csv(result, 'summary.csv')
