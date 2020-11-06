#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(reshape2)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    poplimit <- 5.101e+18
    
    population <- reactive({
        nyears <- input$numyears
        breeders <- as.numeric(input$startingpopulation)
        breedingcycles <- input$breedingcycles
        ageofmaturity <- input$ageofmaturity
        lifespan <- input$lifespan - ageofmaturity    # Calculations work in years of maturity
        numofoffspring <- input$clutchsize
        
        validate(
            need(lifespan >= 0, "Lifespan must equal or exceed age of maturity")
        )
        
        immature <- rep(0, ageofmaturity * breedingcycles)    # Array of breeding cycles of immature subjects
        
        total = data.frame(
            Years = -1:(nyears * breedingcycles) / breedingcycles,
            Total = 0,
            Mature = 0,
            NewMature = 0,
            Immature = 0
        )
        
        if (length(immature) > 0) {    # This allows the proper 'age up' process for gen0
            immature[length(immature)] <- breeders
            breeders <- 0
        }
        
        for (y in 2:nrow(total)) {    # Loop through each breeding cycle
            if (length(immature) > 0) {
                total[y,]$NewMature <- immature[length(immature)]    # Mature the oldest adolescent subjects
                breeders <- breeders + total[y,]$NewMature
                
                if (length(immature) > 1)
                {
                    for (i in (length(immature) - 1):1) {
                        immature[i + 1] <- immature[i]    # Age up remaining young
                    }
                }
                immature[1] <- breeders * numofoffspring
            } else {
                total[y,]$NewMature <- breeders * numofoffspring
                breeders <- breeders + total[y,]$NewMature
            }
            
            if (lifespan > 0 | breedingcycles > 1)
            {
                bornat <- y - lifespan * breedingcycles
                
                if (bornat > 1 & bornat <= nrow(total)) {    # Decease the oldest breeders
                    if (total[bornat,]$NewMature > 0) { breeders <- breeders - total[bornat,]$NewMature }
                }
            } else { breeders <- 0 }
            
            total[y,]$Total <- sum(breeders, immature)
            total[y,]$Mature <- breeders
            total[y,]$Immature <- sum(immature)
            
            if (total[y,]$Total > poplimit)
            {
                total <- total[1:y,]
                break
            }
        }
        total$NewMature <- NULL
        total[2:nrow(total),]
    })
    
    output$popplot <- renderPlotly({
        if (input$logscale) {
            scaletype <- "log"
        } else { scaletype <- "linear" }
        mpop <- melt(population(), id.vars = "Years")
        plot_ly(mpop, x = ~Years, y = ~value, color = ~as.factor(variable), type = "scatter", mode = "lines") %>%
            layout(yaxis = list(title = "Population", type = scaletype))
    })
    
    output$popdf <- renderDataTable({
        pop <- population()
        pop <- pop[order(pop$Years, decreasing = TRUE),]
        yval <- sprintf("%.2f", pop$Years)
        data.frame(
            Years = factor(x = yval, levels = yval, ordered = TRUE),
            Total = format(pop$Total, big.mark = ",", scientific = FALSE),
            Mature = format(pop$Mature, big.mark = ",", scientific = FALSE),
            Immature = format(pop$Immature, big.mark = ",", scientific = FALSE)
        )
    })
    
    output$result <- renderText({
        maxrow <- tail(population(), 1)
        if (maxrow$Total > poplimit)
        {
            paste(
                "If organisms are greater than one squared centimetre in size,",
                "they would cover the surface of the Earth in",
                sprintf("%.2f", maxrow$Years),
                "years."
            )
        } else if (maxrow$Total == 0) {
            paste(
                "The population would become extinct in",
                sprintf("%.2f", maxrow$Years),
                "years."
            )
        } else {
            paste(
                "In",
                sprintf("%.0f", maxrow$Years),
                "years the total projected population at these parameters is",
                format(maxrow$Total, big.mark = ",", scientific = FALSE)
            )
        }
    })
})
