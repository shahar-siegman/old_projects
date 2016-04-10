Mode <- function(x) {
  # statistical mode (most common single entry in sample)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
