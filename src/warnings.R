library(htmltools)
library(docopt)
library(purrr)
library(cli)
library(glue)
library(magrittr, warn.conflicts = FALSE)

glue('covidcast run summarizer

<path> is the directory in which the script expects to find a `results.rds`
file.

Usage:
  {name} --output=<path> <path>
  {name} (-h | --help)
  {name} --version

Options:
  -h --help                 Show this screen.
  --version                 Show version.
  --output=<path>           Where to save the HTML/PDF files
', name = "warnings.R") -> doc

args <- docopt(doc, version = 'covidcast run summarizer 0.1')

# FOR TESTING ONLY
# list(
#   path = c(NA, "../2020-05-24-ctp-allstates-smoothed/longrun.rds")
# ) -> args


local({
  results_path <- file.path(args$path)

  cli_alert_info("Loading results file {.file {results_path}}")
  results <- readRDS(results_path)
  cli_alert_success("Finished")

  # Sort states alphabetically
  dplyr::arrange(results, state)
}) -> results

print_run <- function(result, ...) {
  list(
    h2(paste(list(...), collapse = ',')),
    tags$ol( !!! map(result$warnings, tags$li) )
  )
}

run_warnings <- pmap(results, print_run) %>% flatten

do.call(div, run_warnings) %>%
  save_html(file = "output.html")
