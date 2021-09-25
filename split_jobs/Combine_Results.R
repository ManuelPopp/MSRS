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
args = commandArgs(trailingOnly = TRUE)
wd <- "G:/Projekt"

#----------------------------------------------------------------------|
## file paths
setwd(file.path(wd, "dat"))

#----------------------------------------------------------------------|
## bind saved class frequency data.frames
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)

for(grain in spatial_grains){
  load(file.path(wd, "out", "vrs",
                 paste0("class_frequencies",
                        "_res", grain,
                        ".Rdata")))
  if(!exists("class_freq")){
    class_freq <- class_frequencies
  }else{
    class_freq <- rbind(class_freq, class_frequencies)
  }
}
class_freq$class <- as.factor(class_freq$class)
# save
save(class_freq, file.path(wd, "out", "vrs",
                           paste0("class_freq",
                                  "_res", grain,
                                  ".Rdata")))

#----------------------------------------------------------------------|
## first plots
require("ggplot2")
ggplot(data = class_freq, aes(x = sp_grain, y = perc, colour = class)) +
  geom_point()
ggplot(data = class_freq, aes(x = factor(sp_grain), y = perc, colour = class)) +
  geom_boxplot()
