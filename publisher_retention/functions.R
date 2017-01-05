findDeadTail <- function(data, rel_thres, abs_thres=0) {
  nr <- nrow(data)
  currentAccount <- ''
  res <- logical(nr)
  for (i in 1:nr) {
    rowAccount <- data$account[i]
    if (currentAccount != rowAccount) {
      currentAccount <- rowAccount
      isTail=T
    }
    isTail <- isTail && (data$impressions[i] < rel_thres*data$max_imps[i] ||
                           data$impressions[i] < abs_thres)
    res[i]=isTail
  }
  return(res)
}