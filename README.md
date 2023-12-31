# mpd-interactive
An open-source interactive choropleth map generator for Medicare Part D data, crosswalked with CMS Open Payments data. [Try it out now](https://bailey-inglish.shinyapps.io/mpd-explorer/).

## Code Access
The code used for the data analysis, webapp, and deployment are available in this repository. `mpd-cleaner` was used first to pre-process the data by zip code. `mpd-explorer` then links the summaries to the shapefiles for Texas zip codes and creates an interface for creating choropleth maps with the data. `deploy` contains the code used to deploy the app on shinyapps.io (excluding tokens).

## Data
The data used is too large to upload onto GitHub, so it is available on Box: [https://utexas.box.com/v/mpd-interactive-data](https://utexas.box.com/v/mpd-interactive-data).

To download the Part D and Open Payments datasets, the built-in web viewer interfaces below were used  first used to filter them to only include Texas healthcare providers. For the MPD data, this filter was when `Prscrbr_State_Abrvtn` equals `TX`. For the OP data, the filter was when `Recipient_State` is `TX`.

  - [Medicare Part D Prescribers - by Provider (MPD)](https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider)
  - [Open Payments Data (OP)](https://openpaymentsdata.cms.gov/dataset/0380bbeb-aea1-58b6-b708-829f92a48202)

## Methodology
Zip codes without data available are simply not displayed. Data is only used for 2021, although data is available from the Centers for Medicare and Medicaid Services (CMS) and should be compatible. Note that in some cases, because the Medicare data is only available on a prescriber level, the data for a region is the average *across prescribers*, rather than across *patients*.

## Variable Definitions
The following variables were calculated and are available to select from the dropdown in the app:

- *Proportion of Prescribers Receiving Compensation* (`prop_comp`): The proportion of all prescribers in a zip code who are receiving any amount of reported compensation from drug companies in relation to one or more drug product(s).
- *Mean Compensation Received by Prescribers* (`avg_comp`): The mean amount of reported compensation rendered to prescribers in a zip code by drug companies in relation to one or more drug product(s).
- *Proportion of White, Non-Hispanic Beneficiaries* (`prop_white `): The mean number of beneficiaries per prescriber that are identified by CMS as "White, Non-Hispanic" in a zip code divided by the mean number of total beneficiaries per prescriber that zip code. Values >1 are due to NA exclusion from mean calculations.
- *Proportion of All Claims Used for Opioids* (`prop_opioid`): The mean number of opioid claims from prescribers in a zip code divided by the mean number of total claims from prescribers in that zip code.
- *Mean Drug Spending Per Beneficiary* (`avg_spending_per_bene`): The mean drug costs billed to Medicare by prescribers in a zip code divided by the mean number of beneficiaries in that zip code.
- *Mean Average Prescriber Patient Patient Risk Score (HCC)* (`avg_risk_score`): The mean of the average risk score on the Hierarchical Condition Category (HCC) model of prescribers in a zip code. Redundant mean/average is intentional, HCC is only provided in the data as the average score of patients in each prescriber's care.

## Credits & Thanks
The following packages are used in this app:

 - Tidyverse core
 - Shiny
 - Tigris
 - ZipcodeR

Thank you to Dr. Kyle Walker for his guide to using Tigris to plot Zip Code Tabulation Areas (ZCTAs) with ggplot in Chapters 5-6 of [*Analyzing US Census Data: Methods, Maps, and Models in R*](https://walker-data.com/census-r/index.html). Special thanks to Dr. Layla Parast for teaching me data science :)

The data used in this analysis is all in the public domain, as provided by the federal government for public use through the Centers for Medicaid and Medicare Services and the US Census Bureau.

As requested by some of the authors, certain attributions and citations are below:

Rozzi, G. C. (2021). Zipcoder: Advancing the analysis of spatial data at the ZIP code level in R. *Software Impacts*, 9, 100099. https://doi.org/10.1016/j.simpa.2021.100099 [Article](https://www.sciencedirect.com/science/article/pii/S2665963821000373/) made available under CC BY-NC-ND 4.0. [Package](https://github.com/gavinrozzi/zipcodeR) published under GNU GPL3.

Walker, K. E. (2023). Chapter 5: Census geographic data and applications in R. In *Analyzing US Census Data: Methods, Maps, and Models in R*. CRC Press. Retrieved November 29, 2023, from https://walker-data.com/census-r/index.html. Published under CC BY-NC-ND 4.0.
