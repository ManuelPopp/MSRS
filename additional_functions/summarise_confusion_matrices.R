# Calculate mean values and optionally standard deviation or standard error
# from a list of matrices or confusionMatrix objects
# matr_list : a list of matrices or confusionMatrix objects
# metric : metric to add, either "sd" (standard deviation), "se" (standerd error), or "none"
# add_acc : TRUE/FALSE, add user's and producer's accuracies as additional row/column
# alt_names_r, alt_names_c : alternative row and column names; optional
# latex_file : optional, path to a .tex file that is to be generated
# nice_tex : if TRUE and latex_file set, this creates a nicer version of the table which, however, requires additional LaTeX packages
# d : number of digits to round values in LaTeX table to
# return : TRUE/FALSE, return the output. If false, only a .tex file will be generated
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
