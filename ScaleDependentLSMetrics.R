#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes:
# 1) buildings, 2) roads, 3) agriculture/bare soil 4) forest, 5) water
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "landscapemetrics", "stringr",
              "ggplot2")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- "G:/Projekt"
dir.create(file.path(wd, "fig"))
dir.create(file.path(wd, "out"))

#----------------------------------------------------------------------|
# style
theme_set(theme_classic())
cols <- c(
  rgb(0, 150, 130, maxColorValue = 255), #kit colour
  rgb(70, 100, 170, maxColorValue = 255), #kit blue
  rgb(127, 158, 49, maxColorValue = 255), #dark Mai green
  rgb(35, 161, 224, maxColorValue = 255), #kit cyan
  rgb(163, 16, 124, maxColorValue = 255), #kit violet
  rgb(140, 182, 60, maxColorValue = 255), #kit Mai green
  rgb(223, 155, 27, maxColorValue = 255), #kit orange
  rgb(162, 34, 35, maxColorValue = 255), #kit red
  rgb(167, 130, 46, maxColorValue = 255) #kit braun
)
colz <- c(
  rgb(0, 150, 130, alpha = 255*0.75, maxColorValue = 255),
  rgb(70, 100, 170, alpha = 255*0.75, maxColorValue = 255),
  rgb(104, 133, 43, alpha = 255*0.75, maxColorValue = 255),
  rgb(35, 161, 224, alpha = 255*0.75, maxColorValue = 255),
  rgb(163, 16, 124, alpha = 255*0.75, maxColorValue = 255),
  rgb(140, 182, 60, alpha = 255*0.75, maxColorValue = 255),
  rgb(223, 155, 27, alpha = 255*0.75, maxColorValue = 255),
  rgb(162, 34, 35, alpha = 255*0.75, maxColorValue = 255),
  rgb(167, 130, 46, alpha = 255*0.75, maxColorValue = 255)
)

#----------------------------------------------------------------------|
## file paths
## Landcover 2018
setwd(file.path(wd, "dat"))

LandCover_path <- file.path(wd, "tls", "y")

filenames <- list.files(path = LandCover_path, pattern = ".tif")

#----------------------------------------------------------------------|
## select spatial grain in m
spatial_grains <- c(1, 2, 3, 5, 10, 20, 30)

#----------------------------------------------------------------------|
## Aggregate and calculate statistics
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
    # total area per class
    areas <- landscapemetrics::lsm_c_ca(rst_agg)
    # proportional deviation of the proportion of like adjacencies
    # involving the corresponding class from that expected under a
    # spatially random distribution.
    clumpiness <- landscapemetrics::lsm_c_clumpy(rst_agg)
    # mean patch area
    mean_patch_area <- landscapemetrics::lsm_c_area_mn(rst_agg)
    # CIRCLE describes the ratio between the patch area and the smallest
    # circumscribing circle of the patch and characterises the compactness
    # of the patch.
    mean_cv <- landscapemetrics::lsm_c_circle_mn(rst_agg)
    sd_cv <- landscapemetrics::lsm_c_circle_sd(rst_agg)
    df <- data.frame(tile = rep(str_replace(scene, ".tif", ""),
                                length(areas$class)),
                     sp_grain = rep(grain, length(areas$class)),
                     class = areas$class, area = areas$value,
                     clumpiness = clumpiness$value,
                     mean_patch_area = mean_patch_area$value,
                     mean_circumscr_circ = mean_cv$value,
                     sd_circumscr_circ = sd_cv$value)
    # append summary metrics
    if(!exists("ls_metrics_summary")){
      ls_metrics_summary <- df
    }else{
      ls_metrics_summary <- rbind(ls_metrics_summary, df)
    }
    # increase progress step
    step_i <- step_i + 1
  }
  close(pb)
}
save(ls_metrics_summary, file = file.path(wd, "out", "ls_metrics_summary.Rdata"))
