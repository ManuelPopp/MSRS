#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes:
# 1) buildings, 2) roads, 3) agriculture/bare soil 4) forest, 5) water
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "sf", "rgeos", "rgdal", "caret", "e1071",
              "ggplot2")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- "G:/Projekt"

#----------------------------------------------------------------------|
## file paths
## Landcover 2018
setwd(file.path(wd, "dat"))

RGB_path <- file.path(wd, "tls", "X_RGB")
IR_path <- file.path(wd, "tls", "X_IR")
shp_path <- file.path(wd, "dat", "shp")
filenames <- list.files(path = RGB_path, pattern = ".tif")

#----------------------------------------------------------------------|
## select spatial grain in m; load training polygons
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)

if(!exists("pols")){
  pols <- rgdal::readOGR(file.path(shp_path,
                                   paste0("Train_Polygons_",
                                          max(spatial_grains),
                                          "m.shp")))
}

#----------------------------------------------------------------------|
## Train SVMs at different spatial grains
reduce_sample_size <- function(x, smpl = 50){
  if(nrow(x) > smpl){
    rows <- sample(seq(1, nrow(x), 1), size = smpl)
    out <- x[rows,]
  }else{
    out <- x
  }
  return(out)
}

#for(grain in spatial_grains){}
grain <- spatial_grains[1]

nat_res <- raster::res(raster::stack(file.path(RGB_path,
                                               filenames[1])))
agg_fact <- grain / nat_res[1]

trainval1 <- list()
pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
step_i <- 1
for(i in 1:length(filenames)){
  setTxtProgressBar(pb, step_i)
  cell <- filenames[i]
  R <- raster::raster(file.path(RGB_path, cell), band = 1)
  G <- raster::raster(file.path(RGB_path, cell), band = 2)
  B <- raster::raster(file.path(RGB_path, cell), band = 3)
  IR_1 <- raster::raster(file.path(IR_path, cell), band = 1)
  IR_2 <- raster::raster(file.path(IR_path, cell), band = 2)
  IR_3 <- raster::raster(file.path(IR_path, cell), band = 3)
  X <- raster::stack(R, G, B, IR_1, IR_2, IR_3)
  X_agg <- raster::aggregate(X, fact = agg_fact, fun = mean)
  e <- raster::extent(X_agg)
  ex <- as(e, "SpatialPolygons")
  proj4string(ex) <- proj4string(pols)
  trn_pols <- raster::intersect(pols, ex)
  
  tmp <- raster::extract(X_agg, trn_pols)
  tmp <- lapply(tmp, FUN = reduce_sample_size)
  trainval1 <- c(trainval1, tmp)
  rm("R", "G", "B", "IR_1", "IR_2", "IR_3", "X", "X_agg", "trn_pols", "tmp")
  tmp_dir <- tempdir()
  files <- list.files(tmp_dir, full.names = TRUE, pattern = "^file")
  file.remove(files)
  step_i <- step_i + 1
}
close(pb)

dir.create(file.path(wd, "out", "vrs"), showWarnings = FALSE)
save(trainval1, file = file.path(wd, "out", "vrs", paste0("trainval",
                                                          grain, ".Rdata")))