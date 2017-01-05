source('../../libraries.R')
todayDateString=format(Sys.Date(),'%Y%m%d')
catChange <- function(c3) {
  cat(paste0("\tpositive change: ", sum(c3$change>0),
               ", negative_change: ", sum(c3$change<0),
             "\n"))
  cat(paste0("\tmean positive change: ", c3 %>% filter(change>0) %>% '[['("change") %>% mean() %>% round(3),
               ", mean negative change: ", c3 %>% filter(change<0) %>% '[['("change") %>% mean() %>% round(3),
             "\n"
  ))
}

# loading data
 a <- read.csv(paste0("RevShare_",todayDateString,".csv"), stringsAsFactors = F)
 a1 <- a %>% select(PlacementId, PreviousRevShare, RevShare) %>%
   rename(placement_id=PlacementId)
 b <- read.csv("margin_sheet May31.csv", stringsAsFactors = F)

c1 <- inner_join(a1,b, by="placement_id")
print(sum(is.na(c$url)))
c1 <- c1 %>%
  mutate(actual_rev_share_before=pmin(PreviousRevShare/100,plcmnt_max_margin),
         actual_rev_share_after=pmin(RevShare/100,plcmnt_max_margin))

c2 <- c1 %>% # filter(actual_rev_share_after > actual_rev_share_before+0.05) %>%
  group_by(sitename,url) %>%
  summarise(actual_rev_share_before=
              sum(actual_rev_share_before*url_revenue*placement_fraction_in_url)/
              mean(url_revenue),
            actual_rev_share_after=
              sum(actual_rev_share_after*url_revenue*placement_fraction_in_url)/
              mean(url_revenue),
            url_revenue=mean(url_revenue) ) %>% ungroup() %>%
  arrange(-url_revenue) # %>% filter(abs(actual_rev_share_before-actual_rev_share_after)>5)

write.csv(c2,paste0("margin_calibration_short_term_impact_",todayDateString,".csv"))
c2$change = c2$actual_rev_share_after-c2$actual_rev_share_before


c3 <- c2[1:100,]
ggplot(c3)+geom_histogram(aes(x=change),bins=10) + coord_cartesian(xlim=c(-6,6))
cat("top 100:\n")
catChange(c3)
cat("All:\n")
catChange(c2)






p1 <- ggplot(c) + geom_point(aes(x=actual_rev_share_before, y=actual_rev_share_after))

