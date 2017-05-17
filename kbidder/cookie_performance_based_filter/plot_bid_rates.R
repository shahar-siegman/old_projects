source('../../libraries.R')
a <-
  read.csv('C:/Shahar/Projects/kbidder/Node/user_filtering/data/cookie_sample12_k_sovrn.csv',stringsAsFactors=F) %>%
  filter(requests_in_session <=8) %>%
  mutate(bid_rate_so_far = bids_in_session/requests_in_session,
        bids_in_session_factor = as.factor(bids_in_session),
         requests_in_session_factor = as.factor(requests_in_session),
        placement_id = as.factor(placement_id),
         bid_rate = bids/ impressions,
        bid_value = revenue/ bids,
        is_100percent_fill = bids_in_session==requests_in_session,
        secret_factor = bids_in_session * requests_in_session
  )

k=1
b <- a %>% filter(placement_id == levels(a$placement_id)[1],
                  !is_100percent_fill)

reg = lm(bid_rate ~ bid_rate_so_far + bids_in_session + requests_in_session+secret_factor, b)

b <- b %>% mutate(bid_rate_estimated =  reg$coefficients[1] +
                    bid_rate_so_far * reg$coefficients[2] +
                    bids_in_session * reg$coefficients[3] +
                    requests_in_session*reg$coefficients[4]+
                    secret_factor* reg$coefficients[5])

p1 <- ggplot() +
  geom_line(data = b ,
            aes(x=bids_in_session,y=bid_rate, colour=requests_in_session_factor, group=requests_in_session_factor))+
  geom_point(data = b,
             aes(x=bids_in_session,y=bid_rate_estimated, colour=requests_in_session_factor),size=1.5)+
  geom_line(data = b ,
            aes(x=bids_in_session,y=bid_rate_estimated, colour=requests_in_session_factor, group=requests_in_session_factor),linetype=2)


# p2 <- ggplot(a) +
#   geom_point(aes(x=bid_rate_so_far,y=bid_rate, color=requests_in_session))+
#   facet_wrap(~placement_id, ncol=1)
#
#p3 <- ggplot(a) +
#  geom_line(data= aes(x=bids_in_session,y=bid_value, color=requests_in_session, group=requests_in_session))+
#  facet_wrap(~placement_id, ncol=1)

#print(p3)
