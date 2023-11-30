# Deployment code (uses hidden tokens)
codes <- read_csv("C:/Users/baile/OneDrive - The University of Texas at Austin/Desktop/sds-313/.shiny-tokens.csv") %>%
  filter(app == 1)
rsconnect::setAccountInfo(
  name = "bailey-inglish",
  token = codes$token,
  secret = codes$secret
)
rsconnect::deployApp(
  appDir = "C:/Users/baile/OneDrive - The University of Texas at Austin/Desktop/sds-313/Project 3/",
  appPrimaryDoc = "mpd-explorer.r",
  appName = "mpd-explorer"
)
