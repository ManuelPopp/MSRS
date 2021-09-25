#######################################################################|
# Multi-Skalige Fernerkundung
# under-classification with increasing spatial grain
# - dataset: Luxembourg Land Uda Map 2018
# - classes:
# 1) buildings, 2) roads, 3) agriculture/bare soil 4) forest, 5) water
#######################################################################|
#----------------------------------------------------------------------|
# general settings
packages <- c("raster", "landscapemetrics", "stringr")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- "G:/Projekt"
dir.create(file.path(wd, "out"))

#----------------------------------------------------------------------|
## file paths
## Landcover 2018
setwd(file.path(wd, "dat"))

LandCover_path <- file.path(wd, "tls", "y")

filenames <- list.files(path = LandCover_path, pattern = ".tif")

#----------------------------------------------------------------------|
## Aggregate and calculate statistics
nat_res <- raster::res(raster::raster(file.path(LandCover_path,
                                                  filenames[1])))
grain <- nat_res[1]
  
# start progress bar
pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
step_i <- 1
for(scene in filenames){
  setTxtProgressBar(pb, step_i)
  file <- file.path(LandCover_path, scene)
  rst <- raster::raster(file)
  # total area per class
  areas <- landscapemetrics::lsm_c_ca(rst)
  # proportional deviation of the proportion of like adjacencies
  # involving the corresponding class from that expected under a
  # spatially random distribution.
  clumpiness <- landscapemetrics::lsm_c_clumpy(rst)
  # mean patch area
  mean_patch_area <- landscapemetrics::lsm_c_area_mn(rst)
  # CIRCLE describes the ratio between the patch area and the smallest
  # circumscribing circle of the patch and characterises the compactness
  # of the patch.
  mean_cv <- landscapemetrics::lsm_c_circle_mn(rst)
  sd_cv <- landscapemetrics::lsm_c_circle_sd(rst)
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
  # save step
  save(ls_metrics_summary, file = file.path(wd, "out",
                                            paste0("ls_metrics_summary_step_",
                                            step_i, ".Rdata")))
  # increase progress step
  step_i <- step_i + 1
}
close(pb)

save(ls_metrics_summary, file = file.path(wd, "out", "ls_metrics_summary.Rdata"))