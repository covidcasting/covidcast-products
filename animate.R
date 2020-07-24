#!/usr/bin/Rscript
library(readr)
library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(gganimate)
library(docopt)
library(cli)
library(glue, warn.conflicts = FALSE)

options(warn = 1)

glue('covidestim run animator

Usage:
  {name} --state=<state> -o <output_path> <summary_path>
  {name} (-h | --help)
  {name} --version

Options:
  --state=<state>    Which state to animate. Use state abbreviation, i.e. DC
  -o <output_path>   Where to save the animation
  <summary_path>     The path to the summary .RDS. Must include max_date column
  -h --help          Show this screen.
  --version          Show version.
', name = "animate.R") -> doc

args <- docopt(doc, version = '0.1')

# Include DC in the state.* objects, which aren't included by default
state.name <- c(state.name, "District of Columbia")
state.abb  <- c(state.abb, "DC")

states <- state.name
names(states) <- state.abb

args$state <- states[args$state]

d_all    <- readRDS(args$summary_path)
d        <- filter(d_all, state == args$state)
d_latest <- filter(d, max_date == max(max_date))

x_scale <- scale_x_date(
  date_breaks = '1 week',
  labels = function(breaks) {
    ifelse(lubridate::day(breaks) < 7 | (1:length(breaks) == 1),
           strftime(breaks, '%b %d'),
           strftime(breaks, '%d'))
  },
  minor_breaks = NULL
)

base <- ggplot(d, aes(date, Rt)) +
  geom_hline(yintercept = 1.0, color = 'red') +
  geom_ribbon(aes(ymin = Rt.lo, ymax = Rt.hi), alpha = 0.05, na.rm = TRUE) +
  geom_line(color = 'steelblue3', size = 1.5, na.rm = TRUE) + 
  geom_line(aes(y = Rt.hi), color = 'grey30', size = 0.5, alpha = 0.2, na.rm = TRUE) +
  geom_line(aes(y = Rt.lo), color = 'grey30', size = 0.5, alpha = 0.2, na.rm = TRUE) +
  scale_y_continuous(
    trans = scales::modulus_trans(-1),
    breaks = c(0, seq(0.5, 1.5, 0.1), 2, 3, 4, 5),
    minor_breaks = NULL
  ) +
  x_scale +
  labs(x = NULL) + 
  coord_cartesian(ylim = c(0.0, 5.5), expand = FALSE) +
  theme_bw()

cli_alert_info("Rendering {.code {args$state}}")

# 'distance' is set so that every "trail" produced corresponds to a particular
# day's data, instead of a tweened frame in-between dates
anim <- base + transition_time(max_date) +
  shadow_trail(color = 'grey30', distance = 1/(length(unique(d$max_date))-1))

animate(anim, fps = 30, duration = 10, width = 12, height = 6, units = 'in',
        res = 150, renderer = ffmpeg_renderer())  

cli_alert_success("Finished rendering {.code {args$state}}")
cli_alert_info("Saving {.code {args$state}} to {.file {args$o}}")

anim_save(args$o)

cli_alert_success("Saved {.code {args$state}} to {.file {args$o}}: {prettyunits::pretty_bytes(file.size(args$o))}")
