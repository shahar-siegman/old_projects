
whatif <- function(a3,pid,j)
{
  if (missing(j))
    j <-1

  if(class(a3$placement_id) != "factor")
    a3$placement_id <- as.factor(a3$placement_id)

  if (missing(pid) || str_length(pid)==0)
    pid <- levels(a3$placement_id)[j]

  print(paste0("placement_id: ",pid))
  a3 <- a3 %>% filter(placement_id==pid)

  if (nrow(a3)<10)
  {
    print(paste0("rows to draw: ",nrow(a3),"; exiting"))
    return()
  }


  max_chain_cum_fill <- max(a3$chain_cum_fill)
  bl[[j]] <- b1 %>% filter(placement_id==pid, date %in% unique(a3$date))
  p[[j]] <- ggplot() +
    geom_path(aes(x=chain_cum_fill,y=chain_cum_rcpm,group=chain_codes, colour=chain_codes), data=a3 %>% filter(chain_allocation<0.1), size=0.25, linetype="71")+
    geom_path(aes(x=chain_cum_fill,y=chain_cum_rcpm,group=chain_codes, colour=chain_codes), data=a3 %>% filter(chain_allocation>=0.1), size=1.25)+
    geom_point(aes(x=chain_cum_fill,y=chain_cum_rcpm, colour=chain_codes, shape=as.factor(tag_network)), data=a3, size=3) +
    geom_point(aes(x=chain_cum_fill,y=chain_cum_rcpm, colour=chain_codes, size=chain_allocation^1.5, shape=as.factor(tag_network)), data=a3%>%filter(chain_length==place)) +
    geom_abline(aes(slope=floor_price,intercept=0),data=bl[[j]],colour="black",linetype="dotdash", size=1.25)+
    geom_text(aes(x=chain_cum_fill,y=chain_cum_rcpm,label=sprintf("%1.2f",chain_cum_rcpm/chain_cum_fill)),data=a3%>%filter(chain_length==place), nudge_x = max_chain_cum_fill/25, check_overlap=T)+
    geom_text(aes(x=max_chain_cum_fill*0.9,y=floor_price*max_chain_cum_fill*0.8,label=sprintf("%1.2f",floor_price)),data=bl[[j]],colour="darkgrey")+
    facet_wrap(~date)+
    scale_x_continuous(labels=scales::percent)+
    labs(x="Fill",y="rCPM",shape="Network")

  q[[j]] <- ggplot(data=a3 %>% filter(chain_allocation>=0.01,place==1)) +
    geom_bar(aes(x=factor(1),y=chain_allocation,fill=chain_codes),width=1,position="stack", stat="identity")+
    facet_wrap(~date)+
    scale_y_continuous(labels=scales::percent)

  w <- ggplot()+
    geom_point(aes(x=))
  graphics.off()

  x11(); print(p[[j]]); x11(); print(q[[j]])
}