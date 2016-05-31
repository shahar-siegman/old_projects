source('../../libraries.R')

# loading data
 a <- read.csv("RevShare_20160531.csv", stringsAsFactors = F)
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

write.csv("margin_calibration_short_term_impact.csv",c2)
c2$change = c2$actual_rev_share_after-c2$actual_rev_share_before

c3 <- c2[1:100,]
ggplot(c3)+geom_histogram(aes(x=change),bins=10) + coord_cartesian(xlim=c(-6,6))
print("top 100:")
printChange(c3)
print("All: ")
printChange(c2)

printChange <- function(c3) {
print(paste0(" positive change: ", sum(c3$change>0),
             ", negative_change: ", sum(c3$change>0)))
print(paste0("mean positive change: ", c3 %>% filter(change>0) %>% '[['("change") %>% mean(),
             "mean negative change: ", c3 %>% filter(change<0) %>% '[['("change") %>% mean()
))
}




p1 <- ggplot(c) + geom_point(aes(x=actual_rev_share_before, y=actual_rev_share_after))

