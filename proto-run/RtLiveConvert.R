library(tidyverse)
library(usmap)
library(jsonlite)

d <- read_csv('summary.csv')
d_input <- read_csv('data.csv') %>%
  transmute(date, state,
            input_cases = cases,
            input_deaths = deaths,
            input_volume = round(input_cases / fracpos))

d <- left_join(d, d_input, by = c('date', 'state'))
d <- filter(d, data.available == TRUE)
d <- filter(d, date < max(date) - lubridate::days(2))

# Split each state into its own group, then split each group into its own df
d_split <- d %>% group_by(state) %>% group_split()

# Get a list of the statenames in the split representation. These will then
# be used to key this list of df's
d_statenames <- map_chr(d_split, ~unique(.$state))

# Key the list
d_indexed <- d_split %>% setNames(d_statenames)

# Remove unneeded information and transpose
process_state <- function(df) {

  c("date"           = "date",
    "r0"             = "Rt",
    "r0_l80"         = "Rt.lo",
    "r0_h80"         = "Rt.hi",
    "cases_new"      = "input_cases",
    "corr_cases_new" = "cases.fitted",
    "tests_new"      = "input_volume",
    "deaths_new"     = "input_deaths",
    "onsets"         = "infections",
    "corr_cases_raw" = "input_cases"
  ) -> vars_to_keep

  df <- select_at(df, vars_to_keep)
  df <- setNames(df, names(vars_to_keep))
  df <- mutate(df, date = format(date, '%Y-%m-%d'))

  transpose(df)
}

state_abbrs <- state.abb
names(state_abbrs) <- state.name
state_abbrs = c(state_abbrs, "District of Columbia" = "DC")

restructure_state <- function(lst, state_name) {
  list(
    identifier = state_abbrs[state_name],
    series     = lst,
    population = usmap::statepop[[which(statepop$full == state_name), 'pop_2015']]
  )
}

d_transposed      <- map(d_indexed, process_state)
d_withtags        <- imap(d_transposed, restructure_state)  
names(d_withtags) <- state_abbrs[names(d_withtags)]

list(
  state_data = d_withtags,
  last_updated_ts = 1e3*(lubridate::now() %>% as.POSIXct %>% as.numeric),
  last_r0_date = d$date[length(d$date)] %>% format('%Y-%m-%d')
) -> final

cat(
  toJSON(final, pretty = TRUE, auto_unbox = TRUE, na = 'null'),
  file = "summary.json"
)
