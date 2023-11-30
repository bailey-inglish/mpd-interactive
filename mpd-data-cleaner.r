# The code used to write a .csv file for mpd_pay.
# Not run dynamically for performance reasons.
# Made available here for reproducibility.

# Load libraries and data
library(tidyverse)
setwd("~/") # Set this to wherever you save the data if necessary
mpd_raw <- read_csv("MPD Prescriber Data 2021 TX.csv")
pay_raw <- read_csv("Open Payments Data 2021 TX.csv")
setwd("C:/Users/baile/OneDrive - The University of Texas at Austin/Desktop/sds-313/Project 3/") # change this to whatever your wd is

# Fix the hard-to-read variable names
mpd_clean <- select(
  mpd_raw,
  pbr_npi = PRSCRBR_NPI,
  pbr_zip_code = Prscrbr_zip5,
  total_claims = Tot_Clms,
  total_benes = Tot_Benes,
  total_drug_cost = Tot_Drug_Cst,
  opioid_claims = Opioid_Tot_Clms,
  benes_race_white = Bene_Race_Wht_Cnt, # non-hispanic
  benes_avg_risk_score = Bene_Avg_Risk_Scre # average HCC risk score, measure of how difficult patients are to treat
)

# Also fix the variable names in pay_raw
pay_clean <- select(
  pay_raw,
  pbr_npi = covered_recipient_npi,
  compensation_dollars = total_amount_of_payment_usdollars,
  product_type_1 = indicate_drug_or_biological_or_device_or_medical_supply_1,
  product_type_2 = indicate_drug_or_biological_or_device_or_medical_supply_2,
  product_type_3 = indicate_drug_or_biological_or_device_or_medical_supply_3,
  product_type_4 = indicate_drug_or_biological_or_device_or_medical_supply_4,
  product_type_5 = indicate_drug_or_biological_or_device_or_medical_supply_5
) %>%
  # Subset to only drug-related transactions because of MPD data limits
  filter(
    product_type_1 == "Drug" | product_type_2 == "Drug" | product_type_3 == "Drug" | product_type_4 == "Drug" | product_type_5 == "Drug"
  ) %>%
  select(-starts_with("product_type"), -starts_with("product_specialty"))

# Create a series of aggregates by categories in the format pay_by_*
pay_by_provider <- group_by(pay_clean, pbr_npi) %>%
  summarize(total_compensation = sum(compensation_dollars))

# Merge pay_by_provider to mpd_clean to get a table with pay data and prescribing info
mpd_pay <- left_join(mpd_clean, pay_by_provider, by = "pbr_npi")
mpd_pay$total_compensation[is.na(mpd_pay$total_compensation)] <- 0

# Create a special bool variable for whether or not a pbr is compensated at all
mpd_pay$is_compensated <- mpd_pay$total_compensation > 0

# Provide mean stats on a zip-code-level, then derive stats from those.
stats_by_pbr_zip_code <- group_by(mpd_pay, pbr_zip_code) %>%
  reframe(
    prop_comp = mean(is_compensated, na.rm = TRUE),
    total_compensation = mean(total_compensation, na.rm = TRUE),
    benes_race_white = mean(benes_race_white, na.rm = TRUE),
    total_benes = mean(total_benes, na.rm = TRUE),
    opioid_claims = mean(opioid_claims, na.rm = TRUE),
    total_claims = mean(total_claims, na.rm = TRUE),
    total_drug_cost = mean(total_drug_cost, na.rm = TRUE),
    avg_risk_score = mean(benes_avg_risk_score, na.rm = TRUE),
    pbr_count = n()
  ) %>%
  transmute(
    ZCTA5CE20 = pbr_zip_code,
    prop_comp = round(prop_comp, 2),
    avg_comp = round(total_compensation / total_benes, 2),
    prop_white = round(benes_race_white / total_benes, 2),
    prop_opioid = round(opioid_claims / total_claims, 2),
    avg_spending_per_bene = round(total_drug_cost / total_benes, 2),
    avg_risk_score = round(avg_risk_score, 2),
    pbr_count = pbr_count
  )

# Save the csv to avoid doing this live every time.
write_csv(stats_by_pbr_zip_code, "stats_by_pbr_zip_code.csv")
