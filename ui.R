#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Population Calculator"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            numericInput(
                "startingpopulation",
                "Starting Population (assuming at maturity):",
                min = 2,
                value = 40,
                step = 1),
            sliderInput(
                "breedingcycles",
                "Reproduction cycles per year:",
                min = 1,
                max = 12,
                value = 2,
                step = 1),
            numericInput(
                "clutchsize",
                "Number of offspring per adult:",
                min = 0,
                value = 2,
                step = 1),
            numericInput(
                "ageofmaturity",
                "Age of maturity:",
                min = 0,
                value = 5),
            numericInput(
                "lifespan",
                "Total years the species can expect to live:",
                min = 0,
                value = 15),
            numericInput(
                "numyears",
                "Maximum number of years to calculate",
                min = 1,
                value = 50),
            checkboxInput(
                "logscale",
                "Use Logarithmic Scale",
                value = FALSE
            ),
            textOutput("result")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            tabsetPanel(
                type = "tabs",
                tabPanel(
                    "Plot",
                    br(),
                    plotlyOutput("popplot")
                ),
                tabPanel(
                    "List",
                    br(),
                    dataTableOutput("popdf")
                )
            )
        )
    )
))
