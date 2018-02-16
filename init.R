library(dplyr)
library(tidyr)
library(ggplot2)
library(leaflet)

#### read data & maps ####
btw17    <- readRDS("./data/zweitstimmen.rds")
btw_long <- readRDS("./data/zweitstimmen_long.rds")
turnout_dist   <- readRDS("./data/turnout_dist.rds")
turnout_states <- readRDS("./data/turnout_states.rds")

laender <- readRDS("./maps/Bundeslaender.rds")
kreise  <- readRDS("./maps/Wahlkreise.rds")


#### Color scheme for parties ----
partei_colors <- c(
  CDU = "#262626",
  CSU = "#0000e6",
  SPD = "#ff0000",
  AfD = "#00ccff",
  `DIE LINKE` = "#990099",
  `GRÜNE` = "#39e600",
  FDP = "#ffff1a",
  Sonstige = "#999966"
)
