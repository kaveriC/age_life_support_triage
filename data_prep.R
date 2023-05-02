# This script takes long-form data output from our initial cleaning script
# and formats it appropriately for analysis_train.

# Data is initially "long-form": each row corresponds to 1 hour of a patient's hospitalization.
# It needs to be collapsed to 1 row per Life Support Episode.
# Some extra variables will also be dropped.

library(dplyr)

setwd("C:/Users/t.cri.mhermsen/Documents/UCMC_data_clean/Run_UC_NW_train")

data <- read.csv("output_extra_cols_2-15-23.csv")


data <- data %>%
  group_by(encounter, lfspprt_episode) %>%
  mutate(vent_ever = max(vent)) %>%
  filter(time_icu == 1) %>%
  select(encounter,
         patient,
         lfspprt_episode,
         sofa_total_48hr,
         age_years,
         race,
         sex,
         covid,
         died,
         vent_ever,
         sofa_cv_48hr,
         sofa_resp_48hr,
         sofa_renal_48hr,
         sofa_liver_48hr,
         sofa_coags_48hr,
         sofa_neuro_48hr)

write.csv(data, file="data_for_analysis.csv", row.names=FALSE)
