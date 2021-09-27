# Calculate mean values and optionally standard deviation or standard error
# from a list of matrices or confusionMatrix objects
# matr_list : a list of matrices or confusionMatrix objects
# lates_file : optional, path to a .tex file that is to be generated
# metric : metric to add, either "sd" (standard deviation), "se" (standerd error), or "none"
# add_acc : TRUE/FALSE, add user's and producer's accuracies as additional row/column
# return : TRUE/FALSE, return the output. If false, only a .tex file will be generated
average_matr <- function(matr_list, latex_file = NA,
                         metric = "sd", add_acc = FALSE,
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
    out <- list(matr_mean, matr_sd)
  }else{
    out <- matr_mean
  }
  # generate latex table
  if(is.character(latex_file)){
    if(dir.exists(dirname(latex_file))){
      sink(latex_file)
      cat("% LaTeX Export: Value plusminus ", metric, acc_eval,
          " user's and producer's accuracies.")
      cat("\\hline\n")
      cat(paste(row.names(matr_lst[[1]]), collapse = " & "), "\\\\\n")
      cat("\\hline\n")
      if(length(vec_sd) > 1){
        for(r in 1:nrow(matr_mean)){
          cat(paste(formatC(matr_mean, digits = 1, format = "f"),
                    formatC(matr_sd, digits = 1, format = "f"),
                    sep = " \\(\\pm\\) ", collapse = " & "), "\\\\\n")
        }
      }else{
        for(r in 1:nrow(matr_mean)){
          cat(paste(formatC(matr_mean, digits = 1, format = "f"),
                    collapse = " & "), "\\\\\n")
        }
      }
      cat("\\hline\n")
      sink()
    }else{
      warning("Directory not found: ", latex_file)
    }
  }
  if(return){
    return(out)
  }
}