library(readr)
library(ggplot2)
library(dplyr)
library(gganimate)

d <- read_csv('summary.csv')
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

base <- ggplot(d_latest, aes(date, Rt)) +
  geom_hline(yintercept = 1.0, color = 'red') +
  geom_ribbon(aes(ymin = Rt.lo, ymax = Rt.hi), alpha = 0.05) +
  geom_line(color = 'steelblue3', size = 1.5) + 
  geom_line(aes(y = Rt.hi), color = 'grey30', size = 0.5, alpha = 0.2) +
  geom_line(aes(y = Rt.lo), color = 'grey30', size = 0.5, alpha = 0.2) +
  # scale_y_log10(breaks = c(seq(0.5, 1.5, 0.1), 2, 3, 4, 5),
  #               minor_breaks = NULL) +
  scale_y_continuous(
    trans = scales::modulus_trans(-1),
    breaks = c(0, seq(0.5, 1.5, 0.1), 2, 3, 4, 5),
    minor_breaks = NULL
  ) +
  x_scale +
  labs(x = NULL) + 
  coord_cartesian(ylim = c(0.0, 5.5), expand = FALSE) +
  theme_bw()

base

anim <- base %+% d + transition_time(max_date) + shadow_trail(color = 'grey30')

animate(anim, fps = 30, duration = 30, width = 18, height = 9, units = 'in', res = 150)  

anim_save('animation3.gif')
