library(readr)
library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)

# read data:
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

# aggregate data
btw_long <- btw17 %>%
  select(Laendernamen, `Wahlberechtigte (A)`, `Wähler (B)`, `Ungültige`:`Übrige`) %>%
  gather(key = Partei, value = Stimmen, CDU:`Übrige`) %>%
  group_by(Laendernamen, Partei) %>%
  summarise(
    Prozent = sum(Stimmen) / sum(`Gültige`)
  ) %>%
  mutate(Parteien = ifelse(Prozent <= .05, "Sonstige", Partei)) %>%
  ungroup()


# Color scheme for parties ----
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
