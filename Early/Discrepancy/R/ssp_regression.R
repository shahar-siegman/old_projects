indicators <- read.csv("chains_by_chain.txt",sep="\t")
fit <- lm(indicators$DiscrepancyPercent ~ indicators$e + indicators$o + indicators$p+
            indicators$t + indicators$v + indicators$w + indicators$z)
coefficients(fit)
df_for_plot=data.frame(fitted=fitted(fit),actual=indicators$DiscrepancyPercent)

ggplot(df_for_plot,aes(x=fitted, y=actual)) + geom_point(shape=2) + scale_y_continuous(limits=c(0,1))
