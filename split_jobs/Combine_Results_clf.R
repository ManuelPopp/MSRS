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
packages <- c("dplyr", "lme4", "rstatix", "ggpubr")
for(i in 1:NROW(packages)){
  if(!require(packages[i], character.only = TRUE)){
    install.packages(packages[i])
    library(packages[i], character.only = TRUE)
  }
}
wd <- "G:/Projekt"

#----------------------------------------------------------------------|
## file paths
setwd(file.path(wd, "dat"))
tex_path <- file.path("C:/Users/Manuel/Dropbox/Apps/Overleaf/MSRS/tables")
dir.create(tex_path, showWarnings = FALSE)

#----------------------------------------------------------------------|
# style
theme_set(theme_classic())
cols <- c(
  rgb(162, 34, 35, maxColorValue = 255), #kit red
  rgb(70, 100, 170, maxColorValue = 255), #kit blue
  rgb(140, 182, 60, maxColorValue = 255), #kit May green
  rgb(0, 150, 130, maxColorValue = 255), #kit colour
  rgb(35, 161, 224, maxColorValue = 255), #kit cyan
  rgb(127, 158, 49, maxColorValue = 255), #dark May green
  rgb(163, 16, 124, maxColorValue = 255), #kit violet
  rgb(223, 155, 27, maxColorValue = 255), #kit orange
  rgb(162, 34, 35, maxColorValue = 255), #kit red
  rgb(167, 130, 46, maxColorValue = 255) #kit brown
)
colz <- c(
  rgb(162, 34, 35, alpha = 255*0.75, maxColorValue = 255),
  rgb(70, 100, 170, alpha = 255*0.75, maxColorValue = 255),
  rgb(140, 182, 60, alpha = 255*0.75, maxColorValue = 255),
  rgb(0, 150, 130, alpha = 255*0.75, maxColorValue = 255),
  rgb(35, 161, 224, alpha = 255*0.75, maxColorValue = 255),
  rgb(104, 133, 43, alpha = 255*0.75, maxColorValue = 255),
  rgb(163, 16, 124, alpha = 255*0.75, maxColorValue = 255),
  rgb(223, 155, 27, alpha = 255*0.75, maxColorValue = 255),
  rgb(167, 130, 46, alpha = 255*0.75, maxColorValue = 255)
)

#----------------------------------------------------------------------|
## bind saved class frequency data.frames
spatial_grains <- c(0.4, 1, 2, 4, 10, 20)

for(grain in spatial_grains){
  load(file.path(wd, "out", "vrs",
                 paste0("class_frequencies_classified",
                        "_grn", grain,
                        ".Rdata")))
  if(!exists("class_freq_clf")){
    class_freq_clf <- class_frequencies_classified
  }else{
    class_freq_clf <- rbind(class_freq_clf, class_frequencies_classified)
  }
}
class_freq_clf$class <- as.factor(class_freq_clf$class)
class_freq_clf$sp_grain <- as.ordered(round(class_freq_clf$sp_grain,
                                        digits = 1))

#class_freq_clf <- class_freq_clf[-which(class_freq_clf$class == "0"),]
div <- vector()
for(r in 1:nrow(class_freq_clf)){
  div[r] <- sum(class_freq_clf[which(
    class_freq_clf$tile == class_freq_clf$tile[r] &
      class_freq_clf$sp_grain == class_freq_clf$sp_grain[r]), "count"])
}
class_freq_clf$perc <- class_freq_clf$count / div

# fill in missing classes as zero
for(Tile in unique(class_freq_clf$tile)){
  for(Grain in unique(class_freq_clf$sp_grain)){
    for(Class in unique(class_freq_clf$class)){
      if(length(which(
        class_freq_clf$tile == Tile &
        class_freq_clf$sp_grain == Grain &
        class_freq_clf$class == Class
      )) < 1){
        append <- data.frame(tile = Tile, sp_grain = Grain,
                             class = Class, count = 0, total = NA,
                             perc = 0)
        class_freq_clf <- rbind(class_freq_clf, append)
      }
    }
  }
}

class_freq_clf$tile <- as.factor(class_freq_clf$tile)
class_freq_clf$sp_grain <- as.ordered(class_freq_clf$sp_grain)

# save
save(class_freq_clf, file = file.path(wd, "out", "vrs",
                                  paste0("class_freq_clf",
                                         ".Rdata")))
#----------------------------------------------------------------------|
## get native class frequencies
load(file.path(wd, "out", "ls_metrics_summary.Rdata"))
ls_metrics_summary <- ls_metrics_summary[-which(
  ls_metrics_summary$class == 0),]
ls_metrics_summary$sp_grain <- round(ls_metrics_summary$sp_grain,
                                     digits = 1)
percentual <- function(data){
  dat <- data %>%
    group_by(tile, sp_grain) %>%
    summarise(total_area = sum(area))
  totarea <- as.vector(dat$total_area)
  return(data$area / totarea)
}

ls_metrics_summary$perc <- percentual(ls_metrics_summary)

#----------------------------------------------------------------------|
## first plots
class_freq_clf$native <- rep(NA, nrow(class_freq_clf))
for(r in 1:nrow(class_freq_clf)){
  value <- ls_metrics_summary$perc[
    ls_metrics_summary$tile == class_freq_clf$tile[r] &
      ls_metrics_summary$class == class_freq_clf$class[r]
    ]
  if(is.numeric(value)){
    class_freq_clf$native[r] <- value
  }else{
    cat(paste("Class", class_freq_clf$class[r], "for",
              "tile", class_freq_clf$tile[r], "not occuring."))
    class_freq_clf$native[r] <- 0
  }
}
class_freq_clf$perc_of_native <- class_freq_clf$perc / class_freq_clf$native

require("ggplot2")
gg_1 <- ggplot(data = class_freq_clf, aes(x = factor(sp_grain),
                                      y = perc_of_native,
                                      colour = class)) +
  geom_hline(yintercept = 1, col = "gray") +
  geom_boxplot() +
  scale_color_manual(values = cols) +
  xlab("Ground sampling distance (GSD) in m") +
  ylab("Fraction of cover at 0.2 m GSD") +
  theme(legend.position = "none")

pdf(file = file.path(wd, "fig", "Aggregated_boxpl_clf.pdf"),
    width = 7, height = 4)
print(gg_1)
dev.off()

for(class in 1:5){
  gg_tmp <- ggplot(data = class_freq_clf[
    class_freq_clf$class == unique(class_freq_clf$class)[class],],
    aes(x = factor(sp_grain),
                                              y = perc_of_native,
                                              colour = "black")) +
    geom_hline(yintercept = 1, col = "gray") +
    geom_boxplot() +
    xlab("Ground sampling distance (GSD) in m") +
    ylab("Fraction of cover at 0.2 m GSD") +
    theme(legend.position = "none")
  pdf(file = file.path(wd, "fig", paste0("Aggr_boxpl_clf_class_", class, ".pdf")),
      width = 7, height = 4)
  print(gg_tmp)
  dev.off()
}

#----------------------------------------------------------------------|
## accuracy data
# accuracy matrices from confusion matrices
acc_matr <- function(conf){
  user_acc <- vector()
  for(i in 1:nrow(conf$table)){
    user_acc[i] <- conf$table[i, i] / sum(conf$table[i, ])
  }
  prod_acc <- vector()
  for(i in 1:nrow(conf$table)){
    prod_acc[i] <- conf$table[i, i] / sum(conf$table[, i])
  }
  return(cbind(rownames(conf$table), user_acc, prod_acc))
}

# mean for lists of matrices
average_matr <- function(matr_list, metric = "sd", add_acc = FALSE,
                         alt_names_r = NA, alt_names_c = NA,
                         latex_file = NA, nice_tex = TRUE, d = 1,
                         return = TRUE){
  if(class(matr_list[[1]])[1] == "confusionMatrix"){
    matr_lst <- lapply(matr_list, FUN = function(x){x$table})
  }else{
    matr_lst <- matr_list
  }
  if(add_acc){
    matr_lst <- lapply(matr_lst,
                       FUN = function(x){
                         x <- apply(x, c(1, 2), as.numeric)
                         users <- vector()
                         producers <- vector()
                         for(rc in 1:NROW(x)){
                           users[rc] <- x[rc, rc] / sum(x[rc, ])
                           producers[rc] <- x[rc, rc] / sum(x[, rc])
                         }
                         ret <- rbind(x, producers)
                         return(cbind(ret, c(users, sum(x))))
                       })
    acc_eval <- "with"
  }else{
    acc_eval <- "without"
  }
  vals <- lapply(matr_lst, as.numeric)
  matr <- do.call(cbind, vals)
  #vec_mean <- apply(matr, MARGIN = 1, FUN = mean, na.rm = TRUE)
  vec_mean <- rowMeans(matr, na.rm = TRUE)
  matr_mean <- matrix(vec_mean, nrow = nrow(matr_lst[[1]]))
  if(length(alt_names_r) > 1){
    rownames(matr_mean) <- alt_names_r[1:nrow(matr_mean)]
  }
  if(length(alt_names_c) > 1){
    colnames(matr_mean) <- alt_names_c[1:ncol(matr_mean)]
  }
  if(metric == "sd"){
    vec_sd <- apply(matr, MARGIN = 1, FUN = sd, na.rm = TRUE)
  }else if(metric == "se"){
    vec_sd <- apply(matr, MARGIN = 1,
                    FUN = function(x){sd(x, na.rm = TRUE)/sqrt(length(x))})
  }else{
    vec_sd <- NA
  }
  if(length(vec_sd) > 1){
    matr_sd <- matrix(vec_sd, nrow = nrow(matr_lst[[1]]))
    rownames(matr_sd) <- rownames(matr_mean)
    colnames(matr_sd) <- colnames(matr_mean)
    out <- list(matr_mean, matr_sd)
  }else{
    out <- matr_mean
  }
  # generate latex table
  if(is.character(latex_file)){
    if(dir.exists(dirname(latex_file))){
      if(length(alt_names_r) > 1){
        r_names <- alt_names_r
      }else{
        r_names <- rownames(matr_lst[[1]])
      }
      if(length(alt_names_c) > 1){
        c_names <- alt_names_c
      }else{
        c_names <- colnames(matr_lst[[1]])
      }
      if(nice_tex & (length(vec_sd) > 1)){
        sink(latex_file)
        cat("% LaTeX Export: Value plusminus", metric, acc_eval,
            "user's and producer's accuracies.")
        cat("% Note that this table requires loading the packages 'siunitx' and 'booktabs'.\n")
        cat("\\begin{tabular}{l")
        for(clm in 1:ncol(matr_mean)){
          len_mean <- max(nchar(formatC(matr_mean[, clm], digits = d, format = "f"))) - (d + 1)
          len_sd <- max(nchar(formatC(matr_sd[, clm], digits = d, format = "f"))) - (d + 1)
          if(clm == ncol(matr_mean) & add_acc){
            cat("|S[table-format=", len_mean,
                ".1]@{$\\,\\pm\\,$}S[table-format=", len_sd, ".", d, "]}\n", sep = "")
          }else if(clm == ncol(matr_mean)){
            cat("S[table-format=", len_mean,
                ".1]@{$\\,\\pm\\,$}S[table-format=", len_sd, ".", d, "]}\n", sep = "")
          }else{
            cat("S[table-format=", len_mean,
                ".1]@{$\\,\\pm\\,$}S[table-format=", len_sd, ".", d, "]%\n", sep = "")
          }
        }
        cat("\\toprule\n")
        cat("&", paste(paste0("\\multicolumn{2}{c}{", c_names, "}"),
                  collapse = " & "), "\\\\\n")
        cat("\\midrule\n")
        for(r in 1:nrow(matr_mean)){
          cat(r_names[r],
              paste("", formatC(matr_mean[r, ], digits = d, format = "f"),
                    formatC(matr_sd[r, ], digits = d, format = "f"),
                    sep = " & "), "\\\\\n")
          if(r == (nrow(matr_mean) - 1) & add_acc){
            cat("\\midrule\n")
          }
        }
        cat("\\bottomrule\n")
        cat("\\end{tabular}")
        sink()
      }else{
        sink(latex_file)
        cat("% LaTeX Export: Value plusminus", metric, acc_eval,
            "user's and producer's accuracies.")
        cat("\\hline\n")
        cat(paste(r_names, collapse = " & "), "\\\\\n")
        cat("\\hline\n")
        if(length(vec_sd) > 1){
          for(r in 1:nrow(matr_mean)){
            cat(paste(formatC(matr_mean[r, ], digits = d, format = "f"),
                      formatC(matr_sd[r, ], digits = d, format = "f"),
                      sep = " \\(\\pm\\) ", collapse = " & "), "\\\\\n")
          }
        }else{
          for(r in 1:nrow(matr_mean)){
            cat(paste(formatC(matr_mean, digits = d, format = "f"),
                      collapse = " & "), "\\\\\n")
          }
        }
        cat("\\hline\n")
        sink()
      }
    }else{
      warning("Directory not found: ", latex_file)
    }
  }
  if(return){
    return(out)
  }
}

dir.create(file.path(wd, "out", "tex"), showWarnings = FALSE)

# loop through grains
for(grain in spatial_grains){
  load(file.path(wd, "out", "met", paste0("confmatr", grain, ".Rdata")))
  
  accuracy_matr <- lapply(confusion_matr, FUN = acc_matr)
  
  save(accuracy_matr, file = file.path(wd, "out", "met",
                                       paste0("accmatr",
                                              grain, ".Rdata")))
  
  average_matr(accuracy_matr, metric = "none")
  average_matr(confusion_matr,
               alt_names_r = c("Buildings", "Roads", "Agriculture",
                               "Forest", "Water", "Prod.'s acc."),
               alt_names_c = c("Buildings", "Roads", "Agriculture",
                               "Forest", "Water", "User's accuracy"),
               latex_file = file.path(tex_path,
                                      paste0("Confusion_matr",
                                             grain, ".tex")),
               metric = "sd", add_acc = TRUE)
}
