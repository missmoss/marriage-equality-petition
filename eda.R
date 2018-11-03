library("tidyverse")
library("rbenchmark")
library("scales")
library("ei")

me_raw <- readr::read_csv("marriage_equality.csv")
colnames(me_raw) <- c("city", "site", "volume", "sent", "left", "total")
demo_raw <- readr::read_csv("demographic.csv")
demo_raw <- demo_raw[2:nrow(demo_raw),2:ncol(demo_raw)] %>% # delete duplicate Chinese header
  mutate(population = as.integer(population)) %>%
  mutate(site_id = gsub("　", "", site_id))

bm_demo <- demo_raw[1:10000,] %>%
  mutate(population = as.integer(population))


# https://www.r-bloggers.com/5-ways-to-measure-running-time-of-r-code/
benchmark("group_by_first" = {
  bm <- bm_demo %>%
    group_by(site_id, age, marital_status, edu, sex) %>%
    summarize(population = sum(population)) %>%
    mutate(edu_int = as.integer(factor(edu, levels=unique(bm_demo$edu)[7:1]))) 
},
"replace_first" = {
  bm <- bm_demo %>%
    mutate(edu_int = as.integer(factor(edu, levels=unique(bm_demo$edu)[7:1]))) %>%
    group_by(site_id, age, marital_status, edu_int, sex) %>%
    summarize(population = sum(population))
},
replications = 10,
columns = c("test", "replications", "elapsed",
            "relative", "user.self", "sys.self"))

# replace first wins!
Sys.time()
# [1] "2018-11-02 15:35:39 CDT"
bm <- demo_raw %>%
  mutate(edu_int = as.integer(factor(edu, levels=unique(bm_demo$edu)[7:1]))) %>%
  group_by(site_id, age, marital_status, edu_int, sex) %>%
  summarize(population = sum(population)) %>%
  mutate(college = ifelse(edu_int >= 5, 1, 0), has_spouse = ifelse(marital_status == "有偶", 1, 0))
Sys.time()
# [1] "2018-11-02 15:35:56 CDT"

me <- me_raw %>%
  unite("site_id", c("city", "site"), sep="")

# college
college <- bm %>%
  group_by(site_id, college) %>%
  summarise(population = sum(population)) %>%
  spread(college, population)

names(college) <- c("site_id", "ncollege", "college")

# spouse
spouse <- bm %>%
  group_by(site_id, has_spouse) %>%
  summarise(population = sum(population)) %>%
  spread(has_spouse, population) %>%
  select(site_id, "1")

names(spouse) <- c("site_id", "has_spouse")

data <- college %>%
  mutate(total_pop = college+ncollege) %>%
  mutate(college_percentage = college/total_pop) %>%
  merge(me, all.x = TRUE) %>%
  mutate(sign_percentage = total/total_pop) %>%
  merge(spouse, all.x = TRUE) %>%
  mutate(spouse_percentage = has_spouse/total_pop)

# histogram of sign%
sign_distribution <- ggplot(data) +
  geom_histogram(aes(sign_percentage), bins = 15, fill="#D9934A") +
  labs(title="鄉鎮市區平權公投連署比例分布圖",
       x="平權公投連署比例",
       y="鄉鎮市區數") +
  scale_x_continuous(labels = scales::percent) +
  theme(text=element_text(family = "Noto Sans CJK TC"))
sign_distribution

# top 20 sign%
data %>% 
  dplyr::select(site_id, total, total_pop, sign_percentage) %>%
  arrange(desc(sign_percentage)) %>% 
  top_n(20) %>%
  mutate(sign_percentage = paste(round(sign_percentage, 4)*100,"%",sep="")) %>%
  write_csv("top_20.csv")

# sign% v. college%
spouse_sign <- ggplot(data, aes(x=sign_percentage, y=spouse_percentage)) +
  geom_point(alpha=0.4, color="#D9934A") +
  geom_smooth(method=lm, se=FALSE, color="#04BF9D", size=0.8) +
  labs(title="鄉鎮市區已婚比例及平權公投連署比例",
       x="平權公投連署比例",
       y="已婚比例") +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  theme(text=element_text(family = "Noto Sans CJK TC"))
spouse_sign

# sign% v. college%
college_sign <- ggplot(data, aes(x=sign_percentage, y=college_percentage)) +
  geom_point(alpha=0.4, color="#D9934A") +
  geom_smooth(method=lm, se=FALSE, color="#04BF9D", size=0.8) +
  labs(title="鄉鎮市區大學畢業比例及平權公投連署比例",
       x="平權公投連署比例",
       y="大學畢業比例") +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  theme(text=element_text(family = "Noto Sans CJK TC"))
college_sign


# estimate intervals
# Ti: turnout (fraction who people who voted in precinct i)
# Ti is sign_percentage here
# Xi:  fraction of people who are college degree holders in precinct i
# Xi is college_percentage here
# beta in [max(0, Ti-(1-Xi)/Xi), min(Ti/Xi, 1)]
# Source: Ecological Inference by Simone Zhang
# https://scholar.princeton.edu/sites/default/files/bstewart/files/ecological_inference_slides.pdf

college_estimate <- college %>%
  select(site_id, percentage, sign_percentage) %>%
  mutate(lower=ifelse((sign_percentage-(1-percentage)/percentage)>0,(sign_percentage-(1-percentage)/percentage),0),
         upper=ifelse((sign_percentage/percentage)<1,(sign_percentage/percentage),1))

summary(college_estimate)

# Gary King's EI Package (which is released in 2012 lol)
data2 <- data[!is.na(data$sign_percentage), ]
data2 <- mutate(data2, rescale_sign_p = sign_percentage*10)
form <- rescale_sign_p ~ college_percentage
dbuf <- ei(form,total="total_pop",data=data2)
plot(dbuf, "betab","betaw")

# write csv for reuse
write_csv(data, "data.csv")
