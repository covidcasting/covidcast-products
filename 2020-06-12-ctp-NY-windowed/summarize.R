library(furrr)
library(covidestim)
plan(multicore) # enable multicore execution

d <- readRDS('results.rds')

# Map each for of `d`, row-bind the result, do it in parallel
r <- purrr::pmap_dfr(
  d,
  function(..., result) {
    message(glue::glue("Summarizing {item}",
            item = paste(list(...), collapse='-')))

    tibble::tibble(
      ...,
      # Need to `list` it to avoid binding problems
      summary = list(summary(result$result, index=TRUE))
    )
  }
)

# Unnest the new summary tibble
r_unnest <- tidyr::unnest(r, summary)

readr::write_csv(r_unnest, 'summary.csv')
