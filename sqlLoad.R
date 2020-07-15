#!/usr/bin/Rscript

library(readr)
library(assertthat)
library(lubridate, warn.conflicts = FALSE)
library(dplyr,     warn.conflicts = FALSE)
library(tidyr,     warn.conflicts = FALSE)
library(tibble,    warn.conflicts = FALSE)
library(purrr,     warn.conflicts = FALSE)
library(magrittr,  warn.conflicts = FALSE)

library(cli)
library(docopt)
library(glue, warn.conflicts = FALSE)
library(DBI)
library(RSQLite)

options(warn = 1)

glue('covidestim daily run coalescer

Usage:
  {name} [--file=<name>] --sqlite=<dbfile> --rds=<rdsfile> <path>...
  {name} (-h | --help)
  {name} --version

Options:
  --file=<name>      Within each path, the name of the summary file [default: summary.csv]
  --sqlite=<dbfile>  SQLite file to populate. It will overwrite any existing DB.
  --rds=<rdsfile>    RDS file to populate. It will overwrite any existing file.
  -h --help          Show this screen.
  --version          Show version.
', name = "sqlLoad.R") -> doc

args <- docopt(doc, version = '')

walk(args$path, ~assert_that(is.dir(.))) # Dirs exist?
walk(args$path, ~assert_that(is.readable( file.path(., args$file) ))) # Summaries exist?

cli_alert_info("All summary files appear readable")

paths <- file.path(args$path, args$file)

read_csv <- partial(read_csv, col_types = cols(
  .default = col_double(),
  state = col_character(),
  date = col_date(format = ""),
  data.available = col_logical()
))

cli_process_start("Loading summary files")
allRuns <- tibble(
  df = map(paths, read_csv)
) %>% mutate(max_date = map(df, ~max(.$date)) %>% reduce(c)) %>%
  unnest(max_date) %>% unnest(df)
cli_process_done()

cli_process_start("Saving RDS file")
saveRDS(allRuns, args$rds)
cli_process_done()

cli_process_start("Creating SQLite db")
# Create a DB connection to the SQLite file
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = args$sqlite)

# Destructively overwrite anything there with this table, and set up some
# reasonable indices
copy_to(con, allRuns, "daily_states", overwrite = TRUE, temporary = FALSE,
        indexes = list("date", "max_date", "state", "Rt"))

cli_process_done()

cli_alert_info("{.file {args$rds}}: {prettyunits::pretty_bytes(file.size(args$rds))}")
cli_alert_info("{.file {args$sqlite}}: {prettyunits::pretty_bytes(file.size(args$sqlite))}")
