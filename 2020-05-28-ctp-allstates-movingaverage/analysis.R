suppressPackageStartupMessages( library(tidyverse) )
library(covidcast)
library(gridExtra)
library(cowplot)
library(cli)

path_result <- "results.rds"
path_config <- "config.rds"

cli_alert_info("Loading results file {.file {path_result}}")
d   <- readRDS(path_result)
cli_alert_success("Finished")

cli_alert_info("Loading configuration file {.file {path_config}}")
d_c <- readRDS(path_config)
cli_alert_success("Finished")

d_j <- left_join(d_c, d, by = c('state'))

bind_cols(
  d_j,
  as_tibble(transpose(d_j$config), .name_repair = ~paste0("config.", .)),
  as_tibble(transpose(d_j$result), .name_repair = ~paste0("result.", .))
) %>% select(-config, -result) -> final

simpler <- select(final, state, result = result.result)

cli_alert_info("Producing ggproto visuals and Rt estimations")
mutate(
  simpler,
  plots        = map(result, viz),
  RtNaiveEstim = map(result, RtNaiveEstim),
  RtEstim      = map(result, RtEst)
) %>% arrange(state) -> sp
cli_alert_success("Finished")

# cli_alert_info("Producing ggproto visuals and Rt estimations")
# mutate(
#   simpler[1,],
#   plots        = map(result, viz),
#   RtNaiveEstim = map(result, RtNaiveEstim),
#   RtEstim      = map(result, RtEst)
# ) %>% arrange(state) -> sp_AZ
# cli_alert_success("Finished")

titleRight <- function(gg, title)
  gridExtra::arrangeGrob(
    gg,
    right = title
  )

custom_legend <- theme(
  legend.position = c(0, 1),
  legend.justification = c("left", "top"),
  legend.box.just = "left",
  legend.background = element_rect(fill = alpha("grey", 0.9)),
  legend.margin = margin(6, 6, 6, 6)
)

renderPlots2 <- function(sp) {
  pwalk(
    sp,
    function(state_name,
             result, plots, RtNaiveEstim, RtEstim) {

      cli_alert_info("Producing plots for region {.code {state_name}}")

      x_start <- as.Date('2020/01/20')
      x_end   <- as.Date('2020/05/28')

      x_scale <- scale_x_date(
        limits = c(x_start, x_end),
        date_breaks = '1 week',
        labels = function(breaks) {
          ifelse(lubridate::day(breaks) < 7 | (1:length(breaks) == 1),
                 strftime(breaks, '%b %d'),
                 strftime(breaks, '%d'))
        },
        minor_breaks = NULL
      )

      c(#"Observed and Fitted Cases/Deaths",
        "",
        "Modeled New Infections",
        "Naive R_0(t)",
        "R_t Estimate") -> plot_titles
      
      plots <- plots[c(1,2)] # Exclude delay plot

      plots <- append(plots, list(RtNaiveEstim, RtEstim)) # Add RtEstim plot
      plots <- map(plots, ~. + custom_legend) # Inset legend
      plots <- map(plots, ~. + x_scale) # Nice date axis
      plots <- map(plots, ~. + labs(title = NULL, y = NULL)) # Remove title/ylab
      plots <- cowplot::align_plots(plotlist = plots, align = 'hv') # Align plots
      plots <- map2(plots, plot_titles, titleRight) # Add titles on the right

      allPlots <- gridExtra::grid.arrange(
        plots[[1]],
        plots[[2]],
        plots[[3]],
        plots[[4]],
        nrow = 4,
        ncol = 1,
        top = glue("{state_name}")
      )

      cli_alert_success("Finished")

      allPlots
    }
  )
}

# For debugging
# pdf('plots-WA-may17.pdf', width=11, height=8.5)
# renderPlots2(sp_AZ)
# dev.off()

cli_alert_info("Rendering PDF")
pdf('plots.pdf', width=11, height=8.5)
renderPlots2(sp)
dev.off()
cli_alert_success("Success")
