library(docopt)
library(purrr)
library(cli)
library(glue)
library(magrittr, warn.conflicts = FALSE)
library(pander)

glue('covidcast run summarizer

<path> is the directory in which the script expects to find a `results.rds`
file.

Usage:
  {name} --output=<path> [--name=<name>] <path>
  {name} (-h | --help)
  {name} --version

Options:
  -h --help                 Show this screen.
  --version                 Show version.
  --output=<path>           Where to save the HTML/PDF files
  --name=<name>             Optional name for the run
', name = "warnings.R") -> doc

args <- docopt(doc, version = 'covidcast run summarizer 0.1')

local({
  results_path <- file.path(args$path)

  cli_alert_info("Loading results file {.file {results_path}}")
  results <- readRDS(paste0("../", results_path))
  cli_alert_success("Finished")

  # Sort states alphabetically
  dplyr::arrange(results, state)
}) -> results

rmarkdown::render('runInfo.Rmd')
