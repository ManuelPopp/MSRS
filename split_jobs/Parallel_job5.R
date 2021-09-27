#!/usr/bin/env Rscript
args = commandArgs(trailingOnly = TRUE)
if(length(args) > 1){
  wait <- as.numeric(args[2])
  Sys.sleep(wait)
}
#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes:
# 1) buildings, 2) roads, 3) agriculture/bare soil 4) forest, 5) water
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "sf", "rgeos", "rgdal", "caret", "e1071")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- "G:/Projekt"
lc_classified_path <- file.path(wd, "out", "lcc")
filenames <- list.files(path = lc_classified_path, pattern = ".tif")

#----------------------------------------------------------------------|
## start progress bar
pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
step_i <- 1
for(scene in filenames){
  setTxtProgressBar(pb, step_i)
  file <- file.path(lc_classified_path, paste("Grn", grain,
                                              scene, sep = "_"))
  rst <- raster::raster(file)
  # calculate frequencies per class
  cfreq <- raster::freq(rst)
  cfreq <- data.frame(cfreq)
  sum_pxls <- sum(cfreq[, 2])
  df <- data.frame(tile = rep(str_replace(scene, ".tif", ""),
                              nrow(cfreq)),
                   sp_grain = rep(grain, nrow(cfreq)),
                   class = cfreq[, 1],
                   count = cfreq[, 2],
                   total = rep(sum_pxls, nrow(cfreq))
  )
  df$perc <- df$count / sum_pxls
  # append class frequencies
  if(!exists("class_frequencies")){
    class_frequencies_classified <- df
  }else{
    class_frequencies_classified <- rbind(class_frequencies, df)
  }
  # remove variables
  rm(rst)
  rm(rst_agg)
  # increase progress step
  step_i <- step_i + 1
}
close(pb)
# save per spatial resolution step
save(class_frequencies_classified, file = file.path(wd, "out", "vrs",
                                         paste0("class_frequencies_classified",
                                                "_grn", grain,
                                                ".Rdata")))
rm(class_frequencies_classified)
print("Job done.")