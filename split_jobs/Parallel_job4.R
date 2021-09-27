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

#----------------------------------------------------------------------|
## select spatial grain in m
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)
grain <- spatial_grains[as.numeric(args[1])]

#----------------------------------------------------------------------|
## load model
load(file.path(wd, "out", "mod", paste0("mod", grain, ".Rdata")))

#----------------------------------------------------------------------|
## paths and settings
RGB_path <- file.path(wd, "tls", "X_RGB")
IR_path <- file.path(wd, "tls", "X_IR")
out_path <- file.path(wd, "out", "lcc")
dir.create(out_path, showWarnings = FALSE)

filenames <- list.files(path = RGB_path, pattern = ".tif")

nat_res <- raster::res(raster::stack(file.path(RGB_path,
                                               filenames[1])))
agg_fact <- grain / nat_res[1]

#----------------------------------------------------------------------|
## classify rasters
pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
step_i <- 1
for(i in 1:length(filenames)){
  setTxtProgressBar(pb, step_i)
  cell <- filenames[i]
  # load raster and aggregate
  R <- raster::raster(file.path(RGB_path, cell), band = 1)
  G <- raster::raster(file.path(RGB_path, cell), band = 2)
  B <- raster::raster(file.path(RGB_path, cell), band = 3)
  IR_1 <- raster::raster(file.path(IR_path, cell), band = 1)
  IR_2 <- raster::raster(file.path(IR_path, cell), band = 2)
  IR_3 <- raster::raster(file.path(IR_path, cell), band = 3)
  X <- raster::stack(R, G, B, IR_1, IR_2, IR_3)
  X_agg <- raster::aggregate(X, fact = agg_fact, fun = mean)
  
  # predict and save output
  predict(X_agg, mod, filename = file.path(out_path,
                            paste("Grn", grain, cell, sep = "_")))
  
  # remove variables
  rm("R", "G", "B", "IR_1", "IR_2", "IR_3", "X", "X_agg")
  # clean temp dir
  tmp_dir <- tempdir()
  files <- list.files(tmp_dir, full.names = TRUE, pattern = "^file")
  file.remove(files)
  step_i <- step_i + 1
}
close(pb)