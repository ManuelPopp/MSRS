#!/usr/bin/env Rscript
#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes:
# 1) buildings, 2) roads, 3) agriculture/bare soil 4) forest, 5) water
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "stringr")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
args = commandArgs(trailingOnly = TRUE)
wd <- "G:/Projekt"
dir.create(file.path(wd, "out"))

#----------------------------------------------------------------------|
## file paths
## Landcover 2018
setwd(file.path(wd, "dat"))

LandCover_path <- file.path(wd, "tls", "y")

filenames <- list.files(path = LandCover_path, pattern = ".tif")

#----------------------------------------------------------------------|
## select spatial grain in m
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)

#----------------------------------------------------------------------|
## Aggregate and calculate statistics
if(is.numeric(args[1])){
  spatial_grains <- spatial_grains[args[1]]
}
for(grain in spatial_grains){
  nat_res <- raster::res(raster::raster(file.path(LandCover_path,
                                                  filenames[1])))
  agg_fact <- grain / nat_res[1]
  
  # start progress bar
  pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
  step_i <- 1
  for(scene in filenames){
    setTxtProgressBar(pb, step_i)
    file <- file.path(LandCover_path, scene)
    rst <- raster::raster(file)
    rst_agg <- raster::aggregate(rst, fact = agg_fact, fun = modal)
    # calculate frequencies per class
    cfreq <- raster::freq(rst_agg)
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
      class_frequencies <- df
    }else{
      class_frequencies <- rbind(class_frequencies, df)
    }
    # remove variables
    rm(rst)
    rm(rst_agg)
    # increase progress step
    step_i <- step_i + 1
  }
  # save per spatial resolution step
  save(class_frequencies, file = file.path(wd, "out", "vrs",
                                           paste0("class_frequencies",
                                                  "_res", grain,
                                                  ".Rdata")))
  rm(class_frequencies)
  close(pb)
}