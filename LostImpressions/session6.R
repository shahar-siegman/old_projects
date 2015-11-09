currdir = 'C:/Shahar/Projects/LostImpressions/'

runSession6 <- function() {
  rawDF <- read.csv(paste0(currdir,'experiment_data_aggregated.csv'))
  rawDF <- rawDF %>% filter(!(placement_id %in% c("203047dd1929e08684f45771d064466c", "5af6afe59f7bbb77b82fff5d388f8073")))
  a <- session6Plots(session6(rawDF))
  return(a)
}

session6 <- function(DF) {
  # create fill and lagged fill columns

  # first mobile
  DF$mobile_fill <- DF$true_mobile_served / DF$true_mobile_imps
  DF$mobile_kfill <- DF$mobile_kserved / DF$mobile_kimpressions
  DF <- ddply(DF, "placement_id", function(df) mutate(df, mobile_lag_fill = lag(mobile_fill)))
  DF <- ddply(DF, "placement_id", function(df) mutate(df, mobile_lag_kfill = lag(mobile_kfill)))

  # then global
  DF$global_fill <- DF$true_global_served / DF$true_global_imps
  DF$global_kfill <- DF$nd_kserved / DF$nd_kimpressions
  DF <- ddply(DF, "placement_id", function(df) mutate(df, global_lag_fill = lag(global_fill)))
  DF <- ddply(DF, "placement_id", function(df) mutate(df, global_lag_kfill = lag(global_kfill)))

  # which one looks like a better predictor for mobile_fill, mobile_kfill or global_fill?
  p1 <- ggplot(DF) +
    geom_point(aes(x=mobile_kfill,y=mobile_fill),color="black") +
    geom_smooth(aes(x=mobile_kfill,y=mobile_fill),method="lm") +
    geom_point(aes(x=global_fill,y=mobile_fill),color="magenta") +
    geom_smooth(aes(x=global_fill,y=mobile_fill),method="lm",color="red") +
    facet_wrap(~placement_id)
  # it looks like mobile_kfill. let's build this model and see where the 80% CI passes
  mk_model <- dlply(DF, "placement_id", function(df) lm(mobile_fill ~ mobile_kfill + 0, df, na.action=na.exclude))
  DF$mk_resid <- unlist(lapply(mk_model,residuals))
  DF$mk_fitted <- unlist(lapply(mk_model,fitted.values))
  DF$mk_rel_resid <- abs(DF$mk_resid / DF$mobile_fill)
  DF <- ddply(DF,"placement_id",  ranker)
  CI <- dlply(DF,"placement_id", function(df) max(df[df$rank<=0.8,"mk_rel_resid"]))

#   Browse[3]> unname(unlist(CI))
#   [1] 0.04301168 0.40011811 0.12920934 0.16084275        Inf 0.07674913 0.07236325 0.20445180 0.63232088 1.50248976 0.64917790         NA         NA


  # OK. we won't have this model in reality, because we won't have mobile_fill
  # let's see how closely the global model coefficients approximate the mobile model coefficients
  gk_model <- dlply(DF, "placement_id", function(df) lm(global_fill~ global_kfill + 0, df, na.action=na.exclude))

  coeffs <- data.frame(mk = unlist(lapply(mk_model,coefficients)),
                       gk = unlist(lapply(gk_model,coefficients)))

  p2 <- ggplot(coeffs,aes(x=gk,y=mk))+geom_point()+geom_abline() + geom_abline()

  # Not good enough. let's see how the "returns" are behaving
  DF$mobile_fill_ret <- DF$mobile_fill / DF$mobile_lag_fill - 1
  DF$mobile_kfill_ret <- DF$mobile_kfill / DF$mobile_lag_kfill - 1
  DF$global_fill_ret <- DF$global_fill / DF$global_lag_fill - 1

  p3 <- ggplot(DF) +
    geom_point(aes(x=mobile_kfill_ret,y=mobile_fill_ret),color="black") +
    geom_smooth(aes(x=mobile_kfill_ret,y=mobile_fill_ret),method="lm") +
    geom_point(aes(x=global_fill_ret,y=mobile_fill_ret),color="magenta") +
    geom_smooth(aes(x=global_fill_ret,y=mobile_fill_ret),method="lm",color="red") +
    facet_wrap(~placement_id)

  # looks like it might have some merit. let's assume we have the initial fill
  # and see how well the prediction for the rest goes
  DF <- ddply(DF,"placement_id",predict_using_ret)
  DF$mobile_fill_resid1 <- DF$mobile_fill_predict1 / DF$mobile_fill - 1
  p4 <- ggplot(DF) + geom_density(aes(x=mobile_fill_resid1,y=..scaled..),fill="blue",alpha=0.3, na.rm=T) +
     facet_wrap(~placement_id)

  # hmmm.... this is prone to drift. what if we use the rule of three: mobile_fill = mobile_kfill* global_fill/glboal_kfill
  DF <- ddply(DF,"placement_id",predict_rule3)
  DF$mobile_fill_resid2 <- DF$mobile_fill_predict2 / DF$mobile_fill - 1

  return(DF)
}

ranker <- function(df)
  return(df %>% mutate (rank=percent_rank(df$mk_rel_resid)))

predict_using_ret <- function(df) {
  df <- df %>% mutate(mobile_fill_predict1 = df$mobile_fill[1] * c(1,cumprod(tail(df$mobile_kfill_ret+1,-1))))
  df$mobile_fill_predict[1] <- NA  # perfect prediction, not fair to include in statistics
  return(df)
}

predict_rule3 <- function(df) {
  df <- df %>% mutate(mobile_fill_predict2 = df$mobile_kfill * df$global_lag_fill/df$global_lag_kfill)
  return(df)
}
