#############################
# This is a script containing the main analyses done with the calculated vital-rate specific sensitivities

############################

# 0. Prepare session ############################################

rm(list=ls())


# set wd
setwd("/Users/esinickin/Documents/Master Thesis/MainAnalyses/SciAdv")

# load libraries
library(dplyr)
library(ggplot2)
library(lme4)
library(viridis)
library(effects)
library(tidyr)
library(DHARMa)

# 1. load data #################

# Vital rate specific sensitivities of each species
# alternatively can import the pre-compiled dataframe of all species instead of importing them separately 

dfVR=read.csv("AllSensVR_new.csv")
unique(dfVR$species)


### 2.1 EDA & edit data ###################
str(dfVR)


sum(is.na(dfVR$sens))
sum(is.infinite(dfVR$sens))

hist(dfVR$sens)
# very skewed, mostly between 0 and 1, positive and continuous
# continuous
# always positive
# very right skewed
# probably best dist is gamma dist with log link in the GLMM

hist(dfVR$mat)
max(dfVR$mat)
min(dfVR$mat)

hist(dfVR$n.vr)
hist(dfVR$n.pam)

# add new column with mean number of parameters per vital rate
dfVR$par.per.vr=dfVR$n.pam/dfVR$n.vr

# log-transform age at sexual maturity
dfVR$mat=log(dfVR$mat)
# log-transform also number of vital rates and parameters per vital rate
dfVR$n.vr=log(dfVR$n.vr)
dfVR$par.per.vr=log(dfVR$par.per.vr)


### 2.2 group vital rates #################

# group vital rates into reproduction, survival, or trait change
levels(factor(dfVR$vital.rates))
dfVR[dfVR=="breeding probability"]="reproduction"
dfVR[dfVR=="prop fledging"]="reproduction"
dfVR[dfVR=="prop reproductive"]="reproduction"
dfVR[dfVR=="litter probability"]="reproduction"
dfVR[dfVR=="litter size"]="reproduction"
dfVR[dfVR=="denning survival"]="survival"
dfVR[dfVR=="maturation probability"]="trait change"
dfVR[dfVR=="fecundity"]="reproduction"
dfVR[dfVR=="growth"]="trait change"
dfVR[dfVR=="recruitment"]="reproduction"
dfVR[dfVR=="offspring mass"]="trait change"
dfVR[dfVR=="transition"]="trait change"
dfVR[dfVR=="size"]="trait change"
dfVR[dfVR=="flowering"]="reproduction"
levels(factor(dfVR$vital.rates))


# group (st)ages into non-reproductive and reproductive individuals
levels(factor(dfVR$stage.age))
# non-reproductive
dfVR[dfVR=="fledgling"]="non-reproductive"
dfVR[dfVR=="babies"]="non-reproductive"
dfVR[dfVR=="immature"]="non-reproductive"
dfVR[dfVR=="juvenile"]="non-reproductive"
dfVR[dfVR=="retained juvenile"]="non-reproductive"
dfVR[dfVR=="dispersed juvenile"]="non-reproductive"
dfVR[dfVR=="non-breeder winter"]="non-reproductive"
dfVR[dfVR=="non-breeder summer"]="non-reproductive"
dfVR[dfVR=="non-reproductive adult"]="non-reproductive"
dfVR[dfVR=="sapling"]="non-reproductive"
dfVR[dfVR=="juveniles"]="non-reproductive"
dfVR[dfVR=="calves"]="non-reproductive"
dfVR[dfVR=="yearling"]="non-reproductive"
dfVR[dfVR=="female juvenile"]="non-reproductive"
dfVR[dfVR=="male juvenile"]="non-reproductive"
dfVR[dfVR=="pups"]="non-reproductive"
dfVR[dfVR=="subadult"]="non-reproductive"

# reproductive
dfVR[dfVR=="adult"]="reproductive"
dfVR[dfVR=="breeder winter"]="reproductive"
dfVR[dfVR=="breeder summer"]="reproductive"
dfVR[dfVR=="previous breeder"]="reproductive"
dfVR[dfVR=="previous non-breeder"]="reproductive"
dfVR[dfVR=="reproductive adult"]="reproductive"
dfVR[dfVR=="all"]="reproductive" 
dfVR[dfVR=="adults"]="reproductive"
dfVR[dfVR=="female adult"]="reproductive"
dfVR[dfVR=="male adult"]="reproductive"
dfVR[dfVR=="dominant adult"]="reproductive"
dfVR[dfVR=="helper adult"]="reproductive"

# reindeers and dippers have age classes from 1 to 6 and 1 to 4 respectively
# reindeer stages 2-5 are reproductive
dfVR$stage.age[dfVR$stage.age==2 & dfVR$species=="Rangifer tarandus"]="reproductive"
dfVR$stage.age[dfVR$stage.age==3 & dfVR$species=="Rangifer tarandus"]="reproductive"
dfVR$stage.age[dfVR$stage.age==4 & dfVR$species=="Rangifer tarandus"]="reproductive"
dfVR$stage.age[dfVR$stage.age==5 & dfVR$species=="Rangifer tarandus"]="reproductive"
# reindeer stage 1 & 6 is non-reproductive
dfVR$stage.age[dfVR$stage.age==1 & dfVR$species=="Rangifer tarandus"]="non-reproductive"
dfVR$stage.age[dfVR$stage.age==6 & dfVR$species=="Rangifer tarandus"]="non-reproductive"

# dipper 
dfVR$stage.age[dfVR$stage.age=="age class 1" & dfVR$species=="Cinclus cinclus"]="non-reproductive"
dfVR$stage.age[dfVR$stage.age=="age class 2" & dfVR$species=="Cinclus cinclus"]="reproductive"
dfVR$stage.age[dfVR$stage.age=="age class 3" & dfVR$species=="Cinclus cinclus"]="reproductive"
dfVR$stage.age[dfVR$stage.age=="age class 4" & dfVR$species=="Cinclus cinclus"]="reproductive"

# check
levels(factor(dfVR$stage.age))
levels(factor(dfVR$vital.rates))


# now put stage.age and vital.rates into one column
dfVR$new_vitalrates=paste(dfVR$stage.age, dfVR$vital.rates)
dfVR$new_vitalrates=factor(dfVR$new_vitalrates)

# pool all reproduction together
levels(dfVR$new_vitalrates)[c(1,4)] =c("reproduction","reproduction")
levels(dfVR$new_vitalrates)


## 2.3 make standardized label for drivers ##########
# for the GLMM
# rain-related drivers
dfVR$driver[dfVR$driver %in% c("Pbr", "Pwn", "rain","fallR","Precipitation","precipitation","Rain","Rainfall","ROS","Snow")]="rain"

# temperature stuff
dfVR$driver[dfVR$driver %in% c("lagged temperature","prevwinterT","sea ice","SST","SSTA_b","SSTA_b_l","SSTA_m","SSTA_m_l","summerT","Tat","Tbr","temperature","Temperature","Twn","SST1","SST2","SST3","Q")]="temperature"

# density stuff
dfVR$driver[dfVR$driver %in% c("density","intraD","IntraDens","lagged density")]="density"

# biotic drivers
dfVR$driver[dfVR$driver %in% c("Chla","food","goose abundance","interD","InterDens","lagged food","reindeer carcass availability")]="biotic"


# check
levels(factor(dfVR$driver))


# remove SAM and winterlength
dfVR=dfVR[!dfVR$driver %in% c("SAM","winterlength"),]


levels(factor(dfVR$driver))

# filter df so that we only include climatic covariates 
climate_df=filter(dfVR,driver %in% c("rain","temperature"))
levels(factor(climate_df$driver))
levels(factor(climate_df$species))
levels(factor(climate_df$new_vitalrates))

growth=climate_df[climate_df$new_vitalrates %in% c("non-reproductive trait change","reproductive trait change"),]
levels(factor(growth$species))

# remove trait change because this is what gave huge uncertainties
climate_df=droplevels(climate_df[!climate_df$new_vitalrates%in%c("reproductive trait change","non-reproductive trait change"),])

levels(climate_df$new_vitalrates)
levels(climate_df$driver)





# 3. GLMM: Sens to all Climate Variables ####################################

# remove sens == 0 if there is 
min(climate_df$sens)
climate_df=filter(climate_df,sens!=0) # need to remove zeros because of gamma distribution

# re-define factors
climate_df$species=factor(climate_df$species) # now we have 25 species
climate_df$study.doi=factor(climate_df$study.doi)
climate_df$group=factor(climate_df$group)
climate_df$driver=factor(climate_df$driver)
climate_df$driver.type=factor(climate_df$driver.type)
climate_df$dens=factor(climate_df$dens)
climate_df$biotic_interactions=factor(climate_df$biotic_interactions)


m1 <- glmer(sens ~ new_vitalrates+mat*new_vitalrates + n.vr + par.per.vr + (1+new_vitalrates|group/species) , family = Gamma(link="log"), data = climate_df)

AIC(m1)
summary(m1)

1.439/(1.439+1.499+1.399+9.544e-01)
1.499/(1.439+1.499+1.399+9.544e-01)
1.399/(1.439+1.499+1.399+9.544e-01)
9.544e-01/(1.439+1.499+1.399+9.544e-01)

library(MuMIn)
r.squaredGLMM(m1)

## 3.1 Plot ##################
# plot sens~mat
# pred.df <- data.frame(Effect(c("mat","new_vitalrates","dens"), m1,xlevels=list(mat=seq(min(climate_df$mat), max(climate_df$mat), length.out = 1000), new_vitalrates = levels(climate_df$new_vitalrates),dens=levels(climate_df$dens))))
# 
# levels(pred.df$dens) <- c("No Density Effects","Density Effects",NA)

pred.df <- data.frame(Effect(c("mat","new_vitalrates"), m1,xlevels=list(mat=seq(-0.4, max(climate_df$mat), length.out = 1000), new_vitalrates = levels(climate_df$new_vitalrates))))


levels(pred.df$new_vitalrates) <- c("Reproduction","NR Survival","R Survival",NA)

mean.climate_df = aggregate(sens~species+mat+group+new_vitalrates, mean, data=climate_df[climate_df$mat>(-1),])

levels(mean.climate_df$new_vitalrates) <- c("Reproduction","NR Survival","R Survival")

#pred.df=pred.df[!pred.df$new_vitalrates%in%c("reproductive trait change","non-reproductive trait change"),]
library(ggrepel)

plot.vr <- ggplot(pred.df, aes(x = mat, y = (fit))) +
  geom_ribbon(aes(ymin = (lower), ymax = (upper), fill = new_vitalrates), alpha = 0.2) +
  geom_line(aes(col = new_vitalrates),linewidth=1.2) +
  geom_jitter(data = mean.climate_df, aes(x = mat, y = sens, color = new_vitalrates), alpha = 0.6, size = 5, width = 0, height = 0) +
  
  # facet_grid(dens ~ .) +
  scale_fill_manual(name = "Vital Rates:",values = c("#a8d0eb", "#f5f56c", "#92b954"), labels = c("Reproduction","NR Survival","R Survival")) + 
  scale_color_manual(name = "Vital Rates:",values = c("#a8d0eb", "#f5f56c", "#92b954"), labels = c("Reproduction","NR Survival","R Survival")) +
  labs(
    x = "Log age at sexual maturity (in years)",
    y = "Scaled population growth sensitivities (|S|)") + 
  theme_minimal() +
  geom_text_repel(data = mean.climate_df, aes(x = mat, y = sens, label = species,fontface = "italic"), size = 3.5,
                box.padding = unit(0.4, "lines"), point.padding = unit(0.2, "lines"),
              max.overlaps = 100) +
  theme(axis.title = element_text(size = 22), axis.text = element_text(size = 20),
        strip.text = element_text(size = 20),legend.text = element_text(size = 18),
        legend.title = element_text(size = 20),
        axis.ticks = element_line(color = "black"),
        legend.position = "bottom") 
  # geom_rect(
  #   data = unique(pred.df[c("dens")]),
  #   aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf),
  #   color = "black",
  #   fill = NA,
  #   inherit.aes = FALSE
  # )

plot.vr

ggsave(plot.vr,filename="main_plot_vital_rate.pdf",width=8, height=7)


### Note MARIA: I haven't done those


# 4. Species-specific plots ############
### 4.1 group drivers ##############
# make standardized labels for the drivers
# for the species-specific plots

df=read.csv("AllSensVR_new.csv")
levels(factor(df$driver))

df$vitalrates=paste(df$stage.age,df$vital.rates) # merge stage.age and vital.rates into one column for the plot

levels(factor(df$vitalrates))

# make standardized label for:

# rain-related drivers
df$driver[df$driver %in% c("Pbr", "Pwn", "rain","fallR","Precipitation","precipitation","Rain","Rainfall","ROS","Snow")]="Rain"

# temperature stuff
df$driver[df$driver %in% c("lagged temperature","prevwinterT","sea ice","SST","SSTA_b","SSTA_b_l","SSTA_m","SSTA_m_l","summerT","Tat","Tbr","temperature","Temperature","Twn","SST1","SST2","SST3")]="Temperature"

# density stuff
df$driver[df$driver %in% c("density","intraD","IntraDens","lagged density")]="Density"

# biotic drivers
df$driver[df$driver %in% c("Chla","food","goose abundance","interD","InterDens","lagged food","reindeer carcass availability","biotic")]="Biotic"

# abiotic drivers
df$driver[df$driver %in% c("SAM","winterlength","Q","# dry months","Snow")]="Abiotic"


levels(factor(df$driver))


### 4.2 plot #############
mean.df <- df %>%
  group_by(group, species, driver, vitalrates, dens) %>%
  summarize(mean.sens=mean(sens),
            se.sens=sd(sens)/sqrt(n()) #standard error
  )

levels(factor(mean.df$vitalrates))

# rename the vital rates:
mean.df$vitalrates=factor(mean.df$vitalrates)
levels(mean.df$vitalrates)

levels(mean.df[mean.df$species == "Certhia familiaris",]$vitalrates)

levels(factor(mean.df[mean.df$species == "Cinclus cinclus",]$vitalrates))

levels(factor(mean.df[mean.df$species == "Rangifer tarandus",]$vitalrates))

levels(factor(mean.df[mean.df$species == "Branta leucopsis",]$vitalrates))

# empty list to store all the plots
plots=list()
dodge_width <- 0.4

# loop through all species
for(i in unique(mean.df$species)){
  
  plot=ggplot(subset(mean.df, species == i), aes(x = driver, y = mean.sens, col = vitalrates)) +
    geom_point(position = position_dodge(width = dodge_width), size=4) +
    geom_errorbar(aes(ymin = mean.sens - se.sens, ymax = mean.sens + se.sens), 
                  position = position_dodge(width = dodge_width), 
                  width=0.3, linewidth=0.8) +
    scale_color_viridis_d() +
    theme_minimal() +
    ggtitle(paste(i)) +
    theme(
      axis.title = element_text(size = 24), 
      axis.text = element_text(size = 16),
      # axis.text.x = element_text(angle = 20, hjust = 1, face = "italic"),
      strip.text = element_text(size = 24),
      legend.text = element_text(size = 20),
      legend.title = element_text(size = 24),
      axis.ticks = element_line(color = "black"),
      plot.title = element_text(hjust = 0.5, size = 26, face = "italic")
      # axis.text.x = element_text(angle = 45, hjust = 1),
      #legend.position = "bottom"
    ) + 
    labs(
      x = "",
      y = "Scaled population growth sensitivities |S|",
      col = "Vital rates:"
    ) +
    geom_rect(
      aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf),
      color = "black",
      fill = NA,
      inherit.aes = FALSE
    )
  
  
  plots[[i]]=plot
  
}

plots[[1]]

# save plots
for(i in 1:length(plots)){
  ggsave(filename = paste0("SensVRPlots/",names(plots)[i],".png"),plots[[i]], width = 10, height = 8, dpi = 300)
}



# print plots
for(i in 1:length(plots)){
  print(plots[[i]])
}

# rhabdomys pumilio change vital rate labels
rhabdomys=mean.df[mean.df$species=="Rhabdomys pumilio",]
rhabdomys$vitalrates=factor(rhabdomys$vitalrates)

levels(rhabdomys$vitalrates) <- c("breeding p.","litter p.",
                                  "litter size","immature maturation p.",
                                  "immature survival","non-reproductive adult maturation p.","non-reproductive adult survival","reproductive adult survival")

# plot separately
rhabdomys.plot=ggplot(rhabdomys, aes(x = driver, y = mean.sens, col = vitalrates)) +
  geom_point(position = position_dodge(width = dodge_width), size=4) +
  geom_errorbar(aes(ymin = mean.sens - se.sens, ymax = mean.sens + se.sens), 
                position = position_dodge(width = dodge_width), 
                width=0.3, linewidth=0.8) +
  scale_color_viridis_d() +
  theme_minimal() +
  ggtitle("Rhabdomys pumilio") +
  theme(
    axis.title = element_text(size = 24), 
    axis.text = element_text(size = 18),
    strip.text = element_text(size = 24),
    axis.ticks = element_line(color = "black"),
    plot.title = element_text(hjust = 0.5, size = 26, face = "italic"),
    # axis.text.x = element_text(angle = 45, hjust = 1),
    #legend.position = "bottom"
    legend.text = element_text(size = 12),  # Adjust size for legend text
    legend.title = element_text(size = 12), # Adjust size for legend title
    legend.key.size = unit(0.5, "lines")) + 
  labs(
    x = "",
    y = "Scaled population growth sensitivities |S|",
    col = "Vital rates:"
  ) +
  geom_rect(
    aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf),
    color = "black",
    fill = NA,
    inherit.aes = FALSE
  )

rhabdomys.plot

# save plot
ggsave(filename = "SensVRPlots/Rhabdomys pumilio.png",rhabdomys.plot, width = 10, height = 8, dpi = 300)



# display all plots at the same time
# gridExtra::grid.arrange(grobs = plots[1:4],ncol = 2)
# gridExtra::grid.arrange(grobs = plots[5:8],ncol = 2)
# gridExtra::grid.arrange(grobs = plots[9:12],ncol = 2)
# gridExtra::grid.arrange(grobs = plots[13:16],ncol = 2)
# gridExtra::grid.arrange(grobs = plots[17:20],ncol = 2)
# gridExtra::grid.arrange(grobs = plots[21:23],ncol = 2)
# 
# length(plots)





# 5. Nice plot for publication ###########################

# to show the variability among species

levels(climate_df$species)
levels(climate_df$driver)
levels(climate_df$new_vitalrates)

str(climate_df)

# de-transform mat (aka age at sexual maturity)
min(climate_df$mat)
climate_df$mat=exp(climate_df$mat)
min(climate_df$mat)
max(climate_df$mat)


# load packages if necessary
library(dplyr)
library(ggplot2)
library(ggbeeswarm)
library(viridis)
library(gghalves)


# Create a unique identifier for each species instance
climate_df <- climate_df %>%
  group_by(species) %>%
  mutate(species_instance = paste0(species, "_", row_number())) %>%
  ungroup()

# Reorder species based on age at maturity
species_order <- climate_df %>%
  distinct(species, mat) %>%
  arrange(mat) %>%
  pull(species)

climate_df$species <- factor(climate_df$species, levels = species_order)

levels(climate_df$species)

# re-arrange vital rates and rename them
levels(climate_df$new_vitalrates)

climate_df$new_vitalrates <- factor(climate_df$new_vitalrates)

levels(climate_df$new_vitalrates) <- c("Reproduction","Non-reproductive survival","Reproductive survival")


# all species
quota_halves_allspp <- ggplot(climate_df, aes(x = new_vitalrates, y = sens)) +
  geom_half_point(aes(color = group), 
                  transformation = position_quasirandom(width = 0.1),
                  side = "l", size = 0.5, alpha = 0.5) +
  geom_half_boxplot(aes(fill = group), side = "r") + 
  scale_fill_viridis_d(option = "plasma", end = 0.8) +
  scale_color_viridis_d(option = "plasma", end = 0.8) +
  guides(color = "none", fill = guide_legend(title = "Taxa:")) +
  theme_classic() +
  facet_wrap(~species, scales = "free_y") +
  theme(
    axis.title.x = element_text(size = 13),
    axis.title.y = element_text(size = 13),
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 10),
    strip.text = element_text(size = 9, face = "bold.italic"),
    panel.grid.major.x = element_line(size = 0.5),
    panel.grid.minor.x = element_line(size = 0.25),
    panel.grid.major.y = element_line(size = 0.25),
    panel.grid.minor.y = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    x = "",
    y = "Scaled population growth sensitivities (|S|)",
    color = "Taxa",
    fill = "Taxa"
  )

quota_halves_allspp

ggsave(
  filename = "main_plot_Fig2.tiff",
  plot = quota_halves_allspp,
  device = "tiff",
  dpi = 600,
  width = 13,
  height = 10,
  units = "in",
  compression = "lzw"
)

#ggsave("AllSppVR.png", quota_halves_allspp, width = 13, height = 10, dpi = 300)

