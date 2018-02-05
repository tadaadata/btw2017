library(readr)
library(dplyr)
library(purrr)
library(tidyr)
library(rgdal)


#### read data ####
# skip first 4 lines, set encoding, define delimiter
btw17 <- read_delim("data/btw17_wbz_erststimmen.csv",
                    ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                    trim_ws = TRUE, skip = 4) %>%
  mutate(
    Land = as.integer(Land)
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

btw17 <- btw17 %>%
  mutate(
    # map_chr() runs num2name on every entry of btw17$Land
    Laendernamen = map_chr(Land, num2name)
  )


#### aggregate data ####
btw_long <- btw17 %>%
  select(Laendernamen, `Wahlberechtigte (A)`, `Wähler (B)`, `Ungültige`:`Übrige`) %>%
  gather(key = Partei, value = Stimmen, CDU:`Übrige`) %>%
  group_by(Laendernamen, Partei) %>%
  summarise(
    Prozent = sum(Stimmen) / sum(`Gültige`)
  ) %>%
  mutate(Parteien = ifelse(Prozent <= .05, "Sonstige", Partei)) %>%
  ungroup()


# Voter turnout by states
turnout_states <- btw17 %>%
  group_by(Laendernamen) %>%
  summarise(
    Prozent = sum(`Wähler (B)`) / sum(`Wahlberechtigte (A)`)
  ) %>%
  ungroup()

turnout_dist <- btw17 %>%
  group_by(Wahlkreis) %>%
  summarise(
    Prozent = sum(`Wähler (B)`) / sum(`Wahlberechtigte (A)`)
  ) %>%
  ungroup()


#### read map(s) ####
# Voter Districts
map <- readOGR(dsn   = "./maps/bwl_shapefile",
               layer = "Geometrie_Wahlkreise_19DBT_geo",
               stringsAsFactors = FALSE)

# Federal States
ger <- readRDS("./maps/DEU_adm1.rds")
ger$Prozent <- turnout_states$Prozent


#### write data & maps ####
saveRDS(btw17, "./data/btw17.rds")
saveRDS(btw_long, "./data/btw_long.rds")
saveRDS(turnout_states, "./data/turnout_states.rds")
saveRDS(turnout_dist, "./data/turnout_dist.rds")

saveRDS(map, "./maps/Wahlkreise.rds")
saveRDS(ger, "./maps/Bundeslaender.rds")
rm(laender, leitband)

