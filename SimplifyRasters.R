#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes: Water, Transport
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "rgdal", "dplyr")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- paste0("D:/Dateien/Studium_KIT/Master_GOEK/10_FS_Geooekologie/",
             "Multi-skalige_Fernerkundungsverfahren/Projekt")
#----------------------------------------------------------------------|
## file paths
setwd(file.path(wd, "dat"))

RGB_path <- file.path(wd, "tls", "X_RGB")
IR_path <- file.path(wd, "tls", "X_IR")
LandCover_path <- file.path(wd, "tls", "y")

filenames <- list.files(path = RGB_path, pattern = ".tif")
#----------------------------------------------------------------------|
# aggregate classes
## old classes: 1) buildings, 2) roads, 3) Sand/Gravel/bare soil
## 91) 92) agricultre, 93) vineyards, 6) water, 7) 8) forest
## new classes: 1) buildings, 2) roads, 3) agriculture/bare soil
## 4) forest, 5) water
agg_classes <- function(path){
  r <- raster::raster(path)
  #r <- raster::readAll(r)
  r[r %in% c(91, 92, 93)] <- 3
  r[r %in% c(7, 8)] <- 4
  r[r == 6] <- 5
  dir <- dirname(path)
  out_tmp <- file.path(dir, "tmp.tif")
  raster::writeRaster(r, out_tmp, overwrite = TRUE)
  rm(r)
  if(file.exists(path) & file.exists(out_tmp)){
    file.remove(path)
    file.rename(out_tmp, path)
  }
}

files <- file.path(LandCover_path, filenames)
#sapply(files, agg_classes)

for(path in files){
  r <- raster::raster(path)
  #r <- raster::readAll(r)
  r[r %in% c(91, 92, 93)] <- 3
  r[r %in% c(7, 8)] <- 4
  r[r == 6] <- 5
  dir <- dirname(path)
  out_tmp <- file.path(dir, "tmp.tif")
  raster::writeRaster(r, out_tmp, overwrite = TRUE)
  rm(r)
  if(file.exists(path) & file.exists(out_tmp)){
    file.remove(path)
    file.rename(out_tmp, path)
  }
  tmp_dir <- tempdir()
  tmp_files <- list.files(tmp_dir, full.names = TRUE,
                          pattern = "^file")
  file.remove(tmp_files)
}
