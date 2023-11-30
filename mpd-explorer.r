# Load in relevant libraries.
# Don't forget to use install.package() if you need to.
# setwd("Project 3") development only
library(tidyverse)
library(shiny)
library(tigris)
library(zipcodeR)

stats_by_pbr_zip_code <- read_csv("stats_by_pbr_zip_code.csv") # Read in result of mpd-cleaner.

# A list of the stats in stats_by_pbr_zip_code used in a loop below.
stats_list <- c(
  "prop_comp",
  "avg_comp",
  "prop_white",
  "prop_opioid",
  "avg_spending_per_bene",
  "avg_risk_score"
)

# Dictionary used in graphing to make variable names human-readable.
stats_convert <- c(
  "prop_comp" = "Proportion of Prescribers Receiving Compensation",
  "avg_comp" = "Mean Compensation Received by Prescribers",
  "prop_white" = "Proportion of White, Non-Hispanic Beneficiares",
  "prop_opioid" = "Proportion of All Claims Used for Opioids",
  "avg_spending_per_bene" = "Mean Drug Spending Per Beneficiary",
  "avg_risk_score" = "Mean Average Prescriber Patient Risk Score (HCC)"
)

# Dictionary used to convert human-readable names for color scales to ggplot objects.
scale_fill_convert <- c(
  "White to Green" = scale_fill_gradient(
    low = "white",
    high = "green",
    na.value = NA
  ),
  "Black to Green" = scale_fill_gradient(
    low = "black",
    high = "green",
    na.value = NA
  ),
  "Greyscale" = scale_fill_gradient(
    low = "grey",
    high = "black",
    na.value = NA
  ),
  "Viridis" = scale_fill_viridis_c(na.value = NA),
  "Viridis Logarithmic" = scale_fill_viridis_c(trans = "log", na.value = NA),
  "Viridis Categorical" = scale_fill_viridis_b(na.value = NA)
)

# Imports the Zip Code Tabulation Area (ZCTA) shapefiles for all of the US (can take a moment).
zip <- zctas(
  cb = TRUE,
  year = 2020
)

# Gets the outline of Texas by get all of the states then selecting Texas by its FIPS code (48).
tx_outline <- states(
  cb = TRUE,
  resolution = "500k",
  year = 2020
)
tx_outline <- tx_outline[tx_outline$STATEFP == 48, ]

# Gets a vector of the zip codes for Texas
filter_zip_codes <- search_state("TX")$zipcode

# Selects only the shapefiles for zip codes that are in Texas
zip2 <- zip[is.element(zip$ZCTA5CE20, filter_zip_codes), ]

# Fixes a type mismatch that gets auto-reset upstream and joins the data.
zip2$ZCTA5CE20 <- as.numeric(zip2$ZCTA5CE20)
zip2 <- left_join(zip2, stats_by_pbr_zip_code, by = "ZCTA5CE20")

ui <- fluidPage(
  titlePanel("Texas Medicare Part D & Open Payments Data (Interactive)"),
  h4(em("By Bailey Inglish")),
  hr(),
  sidebarPanel(
    h4("Select Inputs"),
    selectInput(
      inputId = "city",
      label = "Filter by City",
      choices = c(
        "(All)" = "Texas",
        "Houston",
        "San Antonio",
        "Dallas",
        "Austin",
        "Fort Worth",
        "El Paso",
        "Arlington",
        "Corpus Christi",
        "Plano",
        "Lubbock",
        "Laredo",
        "Irving",
        "Garland",
        "The 'sco (Frisco)" = "Frisco", # this is an inside joke
        "McKinney"
      ),
      # Uses Texas as the default for everything
      selected = "Texas"
    ),
    selectInput(
      inputId = "predictor",
      label = "Select Variable of Interest",
      # At least one choice must be selected for the graph.
      choices = c(
        "Proportion of Prescribers Receiving Compensation" = "prop_comp",
        "Mean Compensation Received by Prescribers" = "avg_comp",
        "Proportion of White, Non-Hispanic Beneficiares" = "prop_white",
        "Proportion of All Claims Used for Opioids" = "prop_opioid",
        "Mean Drug Spending Per Beneficiary" = "avg_spending_per_bene",
        "Mean Average Prescriber Patient Risk Score (HCC)" = "avg_risk_score"
      )
    ),
    sliderInput(
      inputId = "range",
      label = "Filter Range of Values Displayed",
      min = min(zip2$prop_comp, na.rm = TRUE),
      max = max(zip2$prop_comp, na.rm = TRUE),
      value = c(min(zip2$prop_comp, na.rm = TRUE), max(zip2$prop_comp, na.rm = TRUE))
    ),
    selectInput(
      inputId = "color",
      label = "Choropleth Color Scale",
      choices = c(
        "White to Green",
        "Black to Green",
        "Greyscale",
        "Viridis", # Using viridis because it is colorblind friendly.
        "Viridis Logarithmic",
        "Viridis Categorical" # Technically satisfies categorical variable requirement!
      )
    ),
    # User chooses whether to display all of Texas or just selected region
    checkboxInput(
      inputId = "border",
      label = "Display Texas Border",
      value = FALSE
    ),
    # Map only generates on button press to conserve resources.
    actionButton(
      inputId = "generate",
      label = "Generate Map"
    )
  ),
  mainPanel(
    h4("Choropleth Map"),
    plotOutput("map"),
    h4("Descriptive Statistics"),
    tableOutput("stats"),
    p("View the code, methodology, and works cited behind this project ", a("here", href = "https://github.com/bailey-inglish/mpd-interactive"), ".")
  )
)

server <- function(input, output) {
  # every time the generate button is pressed, the graph is updated.
  observeEvent(
    input$generate,
    {
      # If the selected city is (All), then all the Texas zip codes (zip2) is passed along. Otherwise, the city is filtered out.
      if (input$city == "Texas") {
        zip3 <- zip2
      } else {
        filter_zip_codes <- search_city(input$city, "TX")$zipcode
        zip3 <- zip2[is.element(zip2$ZCTA5CE20, filter_zip_codes), ]
      }
      # Adjusts the data based on range.
      range_min <- input$range[1]
      range_max <- input$range[2]
      zip3 <- zip3[zip3[[input$predictor]] >= range_min & zip3[[input$predictor]] <= range_max, ]
      # Either sets up blank ggplot or sets up ggplot with outline depending on outline choices.
      if (input$border == TRUE) {
        currentMap <- ggplot() +
          geom_sf(
            data = tx_outline,
            fill = NA
          )
      } else {
        currentMap <- ggplot()
      }
      # Creates a map from shapefile and removes the outlines on zip codes
      currentMap <- currentMap +
        geom_sf(
          data = zip3,
          aes(
            fill = .data[[input$predictor]] # for some reason the data is made bivariate, but .x and .y are equal.
          ),
          color = NA
        ) +
        labs(
          title = str_c(
            "Map of ",
            stats_convert[input$predictor]
          ),
          subtitle = str_c(
            "By ZIP Code in ",
            input$city
          ),
          x = "Longitude",
          y = "Latitude",
          fill = stats_convert[input$predictor]
        ) +
        scale_fill_convert[input$color]
      output$map <- renderPlot(currentMap)
      desc_stats <- tibble(
          Minimum = min(zip3[[input$predictor]], na.rm = TRUE),
          Maximum = max(zip3[[input$predictor]], na.rm = TRUE),
          Mean = mean(zip3[[input$predictor]], na.rm = TRUE),
          Median = median(zip3[[input$predictor]], na.rm = TRUE),
          Standard_Deviation = sd(zip3[[input$predictor]], na.rm = TRUE),
          Number_of_Prescribers = sum(zip3$pbr_count, na.rm = TRUE)
      )
      output$stats <- renderTable(desc_stats)
    }
  )
  observeEvent(
    input$predictor,
    {
      if (input$city == "Texas") {
        zip3 <- zip2
      } else {
        filter_zip_codes <- search_city(input$city, "TX")$zipcode
        zip3 <- zip2[is.element(zip2$ZCTA5CE20, filter_zip_codes), ]
      }
      range_min <- min(zip3[[input$predictor]], na.rm = TRUE)
      range_max <- max(zip3[[input$predictor]], na.rm = TRUE)
      updateSliderInput(
        inputId = "range",
        min = range_min,
        max = range_max,
        value = c(range_min, range_max)
      )
    }
  )
  observeEvent(
    input$city,
    {
      if (input$city == "Texas") {
        zip3 <- zip2
      } else {
        filter_zip_codes <- search_city(input$city, "TX")$zipcode
        zip3 <- zip2[is.element(zip2$ZCTA5CE20, filter_zip_codes), ]
      }
      range_min <- min(zip3[[input$predictor]], na.rm = TRUE)
      range_max <- max(zip3[[input$predictor]], na.rm = TRUE)
      updateSliderInput(
        inputId = "range",
        min = range_min,
        max = range_max,
        value = c(range_min, range_max)
      )
    }
  )
}

shinyApp(ui = ui, server = server)
