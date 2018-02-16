library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(broom)
# library(fs)
library(rgdal)


#### read data ####
# skip first 4 lines, set encoding, define delimiter
# Erststimmen
erst <- read_delim("data/btw17_wbz_erststimmen.csv",
                    ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                    trim_ws = TRUE, skip = 4) %>%
  mutate(
    Bundesland = as.integer(Land)
  )

# Zweitstimmen
zweit <- read_delim("data/btw17_wbz_zweitstimmen.csv",
                    ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                    trim_ws = TRUE, skip = 4) %>%
  mutate(
    Bundesland = as.integer(Land)
  )

# same with data containing all labels
leitband <- read_delim("data/btw17_wbz_leitband.csv",
                       ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                       trim_ws = TRUE, skip = 4)

laender <- leitband[1:16, ]

# build a function to allocate Federal State Name to number
num2name <- function(x = nummer){
  laender$Name[laender$Land == x]
}

erst <- erst %>%
  mutate(
    # map_chr() runs num2name on every entry of btw17$Land
    Bundesland = map_chr(Bundesland, num2name)
  )

zweit <- zweit %>%
  mutate(
    # map_chr() runs num2name on every entry of btw17$Land
    Bundesland = map_chr(Bundesland, num2name)
  )


#### aggregate data ####
erst_long <- erst %>%
  select(Bundesland, `Wahlberechtigte (A)`, `Wähler (B)`, `Ungültige`:`Übrige`) %>%
  gather(key = Partei, value = Stimmen, CDU:`Übrige`) %>%
  group_by(Bundesland, Partei) %>%
  summarise(
    Prozent = sum(Stimmen) / sum(`Gültige`)
  ) %>%
  mutate(Parteien = ifelse(Prozent <= .05, "Sonstige", Partei)) %>%
  ungroup() %>%
  group_by(Bundesland, Parteien) %>%
  summarise(
    Prozent = sum(Prozent, na.rm = T)
  ) %>%
  ungroup()

zweit_long <- zweit %>%
  select(Bundesland, `Wahlberechtigte (A)`, `Wähler (B)`, `Ungültige`:`V-Partei³`) %>%
  gather(key = Partei, value = Stimmen, CDU:`V-Partei³`) %>%
  group_by(Bundesland, Partei) %>%
  summarise(
    Prozent = sum(Stimmen) / sum(`Gültige`)
  ) %>%
  mutate(Parteien = ifelse(Prozent <= .05, "Sonstige", Partei)) %>%
  ungroup() %>%
  group_by(Bundesland, Parteien) %>%
  summarise(
    Prozent = sum(Prozent, na.rm = T)
  ) %>%
  ungroup()

# Voter turnout by states
turnout_states <- erst %>%
  group_by(Bundesland) %>%
  summarise(
    Wahlbeteiligung = sum(`Wähler (B)`) / sum(`Wahlberechtigte (A)`)
  ) %>%
  ungroup()

turnout_dist <- erst %>%
  group_by(Wahlkreis) %>%
  summarise(
    Wahlbeteiligung = sum(`Wähler (B)`) / sum(`Wahlberechtigte (A)`)
  ) %>%
  ungroup()


#### read map(s) ####
# Voter Districts
map <- readOGR(dsn   = "./maps/bwl_shapefile",
               layer = "Geometrie_Wahlkreise_19DBT_geo",
               stringsAsFactors = FALSE)

# Federal States
ger <- readRDS("./maps/DEU_adm1.rds")
ger$Wahlbeteiligung <- turnout_states$Wahlbeteiligung


#### write data & maps ####
saveRDS(erst, "./data/erststimmen.rds")
saveRDS(zweit, "./data/zweitstimmen.rds")
saveRDS(erst_long, "./data/erststimmen_long.rds")
saveRDS(zweit_long, "./data/zweitstimmen_long.rds")
saveRDS(turnout_states, "./data/turnout_states.rds")
saveRDS(turnout_dist, "./data/turnout_dist.rds")

saveRDS(map, "./maps/Wahlkreise.rds")
saveRDS(ger, "./maps/Bundeslaender.rds")
rm(laender, leitband)

