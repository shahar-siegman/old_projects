source('../../libraries.R')

#a <- read.csv('inquisitr.csv',stringsAsFactors = F)
#a$date <- as.Date(a$timestamp,'%Y-%m-%d %H:%M:%S')

a1 <- a %>% filter(placement_id  %in% inquisitr_placements) %>%
  group_by(uid,date) %>%
  summarise(imps=n(),served=sum(ifelse(str_length(served_tag)>=2,1,0)))
a2 <- a1 %>%  filter(imps>20) %>%
  group_by(uid,date) %>%
  summarise(fill=sum(served)/sum(imps),
            imps=sum(imps),
            served=sum(served)) %>%
  mutate(fill_cat=ifelse(fill<0.003,
                         1,
                         ifelse(fill>0.7,
                                3,
                                2)
         )) %>%
  arrange(uid,date)

a3 <- a2 %>% group_by(uid) %>%
  mutate(lag_fill_cat=lag(fill_cat)) %>%
  ungroup() %>%
  mutate(score=
           ifelse(lag_fill_cat==fill_cat,
                  1,
                  ifelse(abs(lag_fill_cat-fill_cat)==1,
                         0,
                         -1))
  )



inquisitr_placements <- c(
'03932d66637d396843a00d741fd3808c',
'05eda0416c8619ca84351b07f46a8852',
'08050f0ec22de78e21b9fed08c02b115',
'139affc1ae629092a7d9acd36557429f',
'1c36189d534fac9b57208103bffe2b23',
'1db7fc316afea90824f2af4949e700dc',
'2d3a4cc3c67dca2c600782323af297e3',
'368e0fcccc64b410342fa97219042791',
'3c8e477f7a98402a588fd5551ccabcff',
'4216f0169b4e7d7dd7ac05271ed1f36b',
'43dd40876b879b2220bc83ba638a9f9d',
'4a176ee86d8eef875953de8bfbd7f064',
'4c469b0a69dfdaa72edf514396bb1dc7',
'4eb156ccb98a4b414bf1c8d12d4b179f',
'64fcf0220f6862095e8cc7b03ae61833',
'6d9fd31416f324bd3f047b470282306f',
'717b7f2bc38049bebe4678acc0729395',
'75379a382b62dcdb5b938574bf2c788d',
'78ab233309dc385d84b1824874ac13e2',
'821c5ab5a662a45b2ff9b32555e138ca',
'8a97ff75214bbc2c4132ab60ed069a20',
'9e5c7560de20f485c9fbcce2bb2d1eeb',
'a5d0af9cac2a8826f02ca1ef2dbf82b7',
'a9b2d818ddfb844039542d09f421a6c3',
'b099e27c6d929509f67c5a04cca99000',
'ca63b0d8bb8d811c0a386065e9008615',
'caf5887a8fa6ec598d061ad42fca7bea',
'd63135fe9a88fddc2ef223b5d3b5bd5a',
'e26ddac6e5246f8424bbefde4e59540e',
'e3ea36ad59e09cb85600fb449a810423',
'f183f58e25d694c9aa1f9201ca79a3c2',
'f32110ad7da2d68cf231d75042d721fa',
'f377d5448539a9a4760ca49df50da92d',
'fed7e1ecb321991dea176156e264d810')