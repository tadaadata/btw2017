#! /usr/bin/env Rscript

rmarkdown::render_site(".")

# Collect output files
out_docs   <- list.files(path = ".", pattern = "*.html", full.names = T)
out_assets <- c("assets", "site_libs")

# Copy files to btsync directory
cur_user <- Sys.info()[["user"]]

if (cur_user == "Lukas") {
  out_dir <- "~/Sync/public.tadaa-data.de/btw17"
} else if (cur_user == "tobi") {
  out_dir <- "~/Dokumente/syncthing/public.tadaa-data.de/btw17/"
} else {
  warning("Don't know who you are, doing nothing")
}

if (!file.exists(out_dir)) {
  dir.create(out_dir)
}

# Move to out_dir
sapply(out_docs,   file.copy, to = out_dir, overwrite = T, recursive = F)
sapply(out_assets, file.copy, to = out_dir, overwrite = T, recursive = T)

