turnout <- readRDS("./data/turnout_states.rds")

arbeitslosigkeit <- read_delim("kovariate/arbeitslosigkeit.csv",
                               "\t", escape_double = FALSE, locale = locale(decimal_mark = ",",
                                                                            encoding = "CP1252"),
                               trim_ws = TRUE, skip = 4) %>%
  rename("Bundesland" = X1, "Jahr" = X2,
         "Quote_zivil" = `Arbeitslosenquote aller zivilen Erwerbspersonen`,
         "Quote_abhg" = `Arbeitslosenquote d. abhängigen ziv. Erwerbspers.`,
         "gemeldete_stellen" = `Gemeldete Arbeitsstellen`) %>%
  group_by(Bundesland) %>%
  summarise(Arbeitslosenquote = mean(Quote_zivil, na.rm = T) / 100) %>%
  ungroup()

migration <- read_delim("kovariate/migrationshintergrund_2011.csv",
                        "\t", escape_double = FALSE, locale = locale(decimal_mark = ","),
                        trim_ws = TRUE, skip = 2) %>%
  rename("ohne_migrationshintergrund" = `ohne Migrations-hintergrund`,
         "mit_migrationshintergrund"  = `mit Migrationshintergrund`) %>%
  select(Bundesland, ohne_migrationshintergrund, mit_migrationshintergrund) %>%
  mutate(ohne_migrationshintergrund = ohne_migrationshintergrund / 100,
         mit_migrationshintergrund  = mit_migrationshintergrund / 100)

einkommen_pc <- read_delim("kovariate/verfuegbares_einkommen_pro_person_1991-2015.csv",
                           "\t", escape_double = FALSE, locale = locale(),
                           trim_ws = TRUE) %>%
  filter(Jahr >= 2010) %>%
  gather(Bundesland, per_capita, -Jahr) %>%
  group_by(Bundesland) %>%
  summarise(per_capita = mean(per_capita)) %>%
  mutate(Bundesland = recode(Bundesland,
                             `BB` = "Brandenburg", `BE` = "Berlin", `BW` = "Baden-Württemberg",
                             `BY` = "Bayern", `HB` = "Bremen", `HE` = "Hessen", `HH` = "Hamburg",
                             `MV` = "Mecklenburg-Vorpommern", `NI` = "Niedersachsen",
                             `NW` = "Nordrhein-Westfalen", `RP` = "Rheinland-Pfalz",
                             `SH` = "Schleswig-Holstein", `SL` = "Saarland", `SN` = "Sachsen",
                             `ST` = "Sachsen-Anhalt", `TH` = "Thüringen"))

abschluesse <- read_delim("kovariate/schulabshluesse_2015-2016.csv",
                          "\t", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                          trim_ws = TRUE, skip = 6) %>%
  mutate(männlich  = as.numeric(ifelse(männlich == "-", NA, männlich)),
         weiblich  = as.numeric(ifelse(weiblich == "-", NA, weiblich)),
         Insgesamt = as.numeric(ifelse(Insgesamt == "-", NA, Insgesamt))) %>%
  filter(!is.na(Insgesamt)) %>%
  group_by(Bundesland, Abschluss) %>%
  summarise(
    # männlich  = sum(männlich),
    # weiblich  = sum(weiblich),
    insgesamt = sum(Insgesamt)
  ) %>%
  ungroup()

abschluesse_alle <- abschluesse %>%
  group_by(Bundesland) %>%
  summarise(gesamt = sum(insgesamt))

abschluesse <- abschluesse %>%
  spread(Abschluss, insgesamt) %>%
  left_join(abschluesse_alle, by = "Bundesland") %>%
  transmute(
    Bundesland = Bundesland,
    Abitur              = `Allgemeine Hochschulreife` / gesamt,
    # Fachabitur          = `Fachhochschulreife` / gesamt,
    Hauptschulabschluss = `Hauptschulabschluss` / gesamt,
    Mittlerer_Abschluss = `Mittlerer Schulabschluss` / gesamt,
    ohne_Abschluss      = `Ohne Hauptschulabschluss` / gesamt
  )

temp1 <- turnout %>%
  left_join(abschluesse, by = "Bundesland") %>%
  left_join(arbeitslosigkeit, by = "Bundesland") %>%
  left_join(einkommen_pc, by = "Bundesland") %>%
  left_join(migration, by = "Bundesland")

rm(abschluesse, abschluesse_alle, arbeitslosigkeit, einkommen_pc, migration, turnout)

# Anmerkungen:
# "echte Zählung der Verdächtigen" ergibt andere Zahlen als die einfache
# Summer aller Bundesländer - keine Ahnung, woher der Unterschied kommt

opfer <- read_delim("kovariate/kriminalstats/bka2016_opfer_delikte_laender.csv",
                    ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                    trim_ws = TRUE, skip = 1)[, 1:7] %>%
  rename(Opfer_gesamt = `Opfer insgesamt - Anzahl`,
         Opfer_m = `Opfer insgesamt maennlich- Anzahl`,
         Opfer_w = `Opfer insgesamt weiblich- Anzahl`) %>%
  filter(Fallstatus == "insg.", Bundesland != "Bund echte Zaehlung der Tatverdaechtigen") %>%
  select(-Fallstatus)

opfer_gesamt <- filter(opfer, Straftat == "Straftaten insgesamt")


taeter_d <- read_delim("kovariate/kriminalstats/bka2016_tatverdaechtige_delikte_deutsch_laender.csv",
                       ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                       trim_ws = TRUE, skip = 1)[, 1:5] %>%
  rename(geschl = Sexus, Taeter_gesamt = `Tatverdaechtige deutsch insgesamt - Anzahl`) %>%
  filter(Bundesland != "Bund echte Zaehlung der Tatverdaechtigen") %>%
  spread(geschl, Taeter_gesamt) %>%
  rename(taeter_deutsch_m = M, taeter_deutsch_w = W, taeter_deutsch_gesamt = X)

hetze <- filter(taeter_d, str_detect(Straftat, "Volksverhetzung"))

taeter_nd <- read_delim("kovariate/kriminalstats/bka2016_tatverdaechtige_delikte_nichtdeutsch_laender.csv",
                        ";", escape_double = FALSE, locale = locale(encoding = "CP1252"),
                        trim_ws = TRUE, skip = 1)[, 1:5] %>%
  rename(geschl = Sexus, Taeter_gesamt = `Tatverdaechtige nichtdeutsch insgesamt - Anzahl`) %>%
  filter(Bundesland != "Bund echte Zaehlung der Tatverdaechtigen") %>%
  spread(geschl, Taeter_gesamt) %>%
  rename(taeter_nichtdeutsch_m = M, taeter_nichtdeutsch_w = W, taeter_nichtdeutsch_gesamt = X)

bevoelkerung <- read_csv("kovariate/bevoelkerung.csv")

## join data
temp2 <- filter(opfer, Straftat == "Straftaten insgesamt")
temp3 <- filter(taeter_d, Straftat == "Straftaten insgesamt")
temp4 <- filter(taeter_nd, Straftat == "Straftaten insgesamt")

temp5 <- left_join(temp2, temp3, by = "Bundesland") %>%
  left_join(., temp4, by = "Bundesland") %>%
  left_join(., bevoelkerung, by = "Bundesland") %>%
  mutate(Bundesland = str_replace(Bundesland, "ue", "ü")) %>%
  select(-dplyr::contains("Schluessel"), -dplyr::contains("Straftat")) %>%
  # convert numbers to x per 100.000 Residents,
  # -> reflect in labels later on
  transmute(
    Bundesland  = Bundesland,
    Bevölkerung = Bevölkerung_gesamt,
    Opfer       = Opfer_gesamt * 100000 / Bevölkerung_gesamt,
    Taeter_deutsch      = taeter_deutsch_gesamt * 100000 / Bevölkerung_gesamt,
    Taeter_nichtdeutsch = taeter_nichtdeutsch_gesamt * 100000 / Bevölkerung_gesamt
  )

gesamt <- left_join(temp1, temp5, by = "Bundesland")

saveRDS(gesamt, "./kovariate/kovariate_gesamt.rds")
rm(bevoelkerung, opfer, opfer_gesamt, taeter_d, taeter_nd, temp1, temp2, temp3, temp4, temp5)
