library(tidyverse)
library(covidestim)

covidcast_register()

tribble(
  ~fname,               ~state,     ~setup,
  "alpha-Kansas.rds",   "Kansas",   "alpha",
  "alpha-Maryland.rds", "Maryland", "alpha",
  # "alpha-Michigan.rds", "Michigan", "alpha",
  "alpha-Nebraska.rds", "Nebraska", "alpha",
  "beta-Kansas.rds",    "Kansas",   "beta",
  "beta-Maryland.rds",  "Maryland", "beta",
  "beta-Michigan.rds",  "Michigan", "beta",
  "beta-Nebraska.rds",  "Nebraska", "beta"
) -> runList

runList <- mutate(runList, result = map(fname, readRDS))

runList <- mutate(runList, warnings = map(result, ~.$result[[1]]$warnings))

runList <- mutate(runList, summary = map(result, ~summary(.$result[[1]]$result)))

summary_df <- transmute(runList, state, setup, summary)

summary_df <- unnest(summary_df, summary)

write_csv(summary_df, 'summary.csv')

