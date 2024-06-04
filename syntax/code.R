# libraries
library(tidyr)
library(dplyr)
library(stringr)
library(readxl)
library(stringdist)
library(tidyverse)
library(openxlsx)
library(readr)
library(scales)
library(sf)
library(stargazer)
library(Hmisc)

## download geospatial data from each website
# for cejst: "https://screeningtool.geoplatform.gov/en/downloads"
# for dac: "https://energyjustice.egs.anl.gov/"
# for ej: "https://www.epa.gov/ejscreen/download-ejscreen-data"

DAC <- ej %>% 
  dplyr::select(GEOID) %>% 
  st_join(cejst %>% 
            rename(ID = GEOID) %>% 
            dplyr::select(ID), largest = TRUE) 


DAC_whole <- DAC %>% 
  left_join(ej %>% 
              st_drop_geometry(), by = "GEOID") %>% 
  left_join(cejst %>%
              st_drop_geometry() %>% 
              left_join(dac %>% 
                          st_drop_geometry(), by = "GEOID") %>% 
              rename(ID = GEOID), by = "ID")
  
write_csv(DAC_whole %>% 
            st_drop_geometry() %>% 
            dplyr::select(-ID), "./results/DAC.csv")

save(DAC, file = "./results/DAC.Rdata")


## short version 
# r regex 
ft <- c(grep(pattern="90th",
             colnames(cejst)), 
        grep(pattern="underinvestment|mine|FUDS",
             colnames(cejst)),
        grep(pattern="low income|low HS",
             colnames(cejst)))

ord <- c(ft[duplicated(ft)],
         which(colnames(cejst) == "Identified as disadvantaged"))

nm <- colnames(cejst)[ord[order(ord)]][-31:-33] # remove duplicated variables for (island areas)

nm <-  nm %>%
  gsub(".*for (.*?) and.*", "\\1", .) %>%
  ifelse(sapply(strsplit(.," "), length) > 12,
         gsub(".*by (.*?) or.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 10,
         gsub("^(.*?) as.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 9,
         gsub(".*at (.*?) in.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 7,
         gsub(".*federal (.*?)$", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 7,
         gsub(".*historic (.+) and.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 5,
         gsub(".*Used (.+) \\(FUDS\\).*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 3,
         gsub(".*one (.*?)$", "\\1", .), .) %>%
  gsub("^(.*?),.*", "\\1", .) %>% 
  gsub(".*as (.*?)$", "\\1", .) %>% 
  tolower()

colnames(cejst)[ord[order(ord)]][-31:-33] <- nm

cejst <- cejst %>% 
  dplyr::select(GEOID, ord[order(ord)][-31:-33]) 



DAC_sub <- DAC %>% 
  left_join(ej %>% 
              st_drop_geometry() %>% 
              dplyr::select(matches("GEOID|PCT|D2|D5")) %>% 
              dplyr::select(!matches("P_|1960")), by = "GEOID") %>% 
  left_join(cejst %>%
              st_drop_geometry() %>% 
              left_join(dac %>% 
                          st_drop_geometry() %>% 
                          dplyr::select(GEOID, DACSCORE), by = "GEOID") %>% 
              rename(ID = GEOID), by = "ID")

write_csv(DAC_sub %>% 
            st_drop_geometry() %>% 
            dplyr::select(-ID), "./results/DAC_s.csv")

