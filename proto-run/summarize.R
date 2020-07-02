#!/usr/bin/env Rscript

library(rslurm)

library(docopt)
library(readr)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(assertthat)
library(purrr, warn.conflicts = FALSE)
library(glue,  warn.conflicts = FALSE)
library(cli)
library(stringr)

glue('covidestim SLURM summarizer

Usage:
  {name} <sjob>
  {name} (-h | --help)
  {name} --version

Options:
  -h --help                 Show this screen.
  --id-vars=<vars>          Grouping vars in <path>, separated by commas. [default: state]
  --version                 Show version.
', name = "summarize.R") -> doc

args <- docopt(doc, version = 'covidestim SLURM summarizer 0.1')

sjob    <- readRDS(args$sjob)
d       <- get_slurm_out(sjob, outtype = 'table')

result <- select_at(d, c('group_name', 'summary')) %>% tibble::as_tibble %>% unnest(summary)

readr::write_csv(result, 'summary.csv')
