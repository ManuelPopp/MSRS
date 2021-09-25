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
## select spatial grain in m
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)
grain <- spatial_grains[as.numeric(args[1])]

#----------------------------------------------------------------------|
## load data
shp_path <- file.path(wd, "dat", "shp")
if(!exists("pols")){
  pols <- rgdal::readOGR(file.path(shp_path,
                                   paste0("Train_Polygons_",
                                          max(spatial_grains),
                                          "m.shp")))
}

if(!exists("trainval1")){
  load(file.path(wd, "out", "vrs", paste0("trainval", grain, ".Rdata")))
}

points_per_poly <- nrow(trainval1[[1]])

# training data table
trnval1 <- do.call(rbind, trainval1)

# training classes vector
trnclass <- rep(as.factor(pols@data$layer), each = points_per_poly)

#----------------------------------------------------------------------|
## tune SVM
set.seed(1337)
#sigma <- quantile(as.vector(
#  dist(trnval1[sample(seq(1, nrow(trnval1)), 1000), ])
#  ), 1/5)
#g <- 1 / (2*sigma^2)

gammat = seq(0.1, 2, by = .1)
costt = seq(1, 152, by = 12)

tune1 <- tune.svm(trnval1, as.factor(trnclass),
                  gamma = gammat, cost = costt)
save(tune1, file = file.path(wd, "out", "vrs", paste0("tune",
                                                      grain, ".Rdata")))

if(!exists("tune1")){
  load(file.path(wd, "out", "vrs", paste0("tune", grain, ".Rdata")))
}

gamma <- tune1$best.parameters$gamma
cost <- tune1$best.parameters$cost

#----------------------------------------------------------------------|
## train SVM
print("Training SVM...")
mod <- e1071::svm(trnval1, as.factor(trnclass),
           gamma = gamma, cost = cost,
           probability = TRUE, cross = 5)
save(mod, file = file.path(wd, "out", "vrs", paste0("mod",
                                                    grain, ".Rdata")))
sink(file.path(wd, "out", paste0("ModSummary_", grain, ".txt")))
summary(mod)
sink()

#----------------------------------------------------------------------|
## get confusion matrix
confusion_matr <- list()
trntst <- cbind(as.factor(trnclass), trnval1)

print("Model evaluation loop started.")
N_it <- 5
pb = txtProgressBar(min = 0, max = length(filenames), initial = 0)
for(i in 1:N_it){
  setTxtProgressBar(pb, i)
  spl <- sample(seq(1, nrow(trntst)), nrow(trntst), replace = TRUE)#floor(nrow(trntst)/3))
  trn <- trntst[-spl,]
  tst <- trntst[spl,]
  
  mod_tmp <- e1071::svm(trn[, 2:ncol(trn)], as.factor(trn[, 1]),
             gamma = gamma, cost = cost, probability = TRUE)
  pred <- predict(mod_tmp, tst[, -1], probability = FALSE)
  
  if(nlevels(pred) == nlevels(trnclass)){
    confusion_matr[[i]] <- caret::confusionMatrix(pred,
                                                  as.factor(tst[, 1]))
  }else{
    print("Classes missing in predicted values.")
  }
}
close(pb)

dir.create(file.path(wd, "out", "met"), showWarnings = FALSE)
save(confusion_mat, file.path(wd, "out", "met", paste0("confmatr",
                                                       grain, ".Rdata")))

acc_matr <- function(conf){
  user_acc <- vector()
  for(i in 1:nrow(conf)){
    user_acc[i] <- conf[i, i] / sum(conf[i, ])
  }
  prod_acc <- vector()
  for(i in 1:ncol(conf)){
    prod_acc[i] <- conf[i, i] / sum(conf[, i])
  }
  return(cbind(rownames(conf), user_acc, prod_acc))
}
accuracy_matr <- lapply(confusion_matr, FUN = acc_matr)
save(accuracy_matr, file.path(wd, "out", "met", paste0("accmatr",
                                                       grain, ".Rdata")))
print("Job finished.")
