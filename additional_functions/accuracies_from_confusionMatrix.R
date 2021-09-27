# calculate user's and producer's accuracies from a confusionMatrix object
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