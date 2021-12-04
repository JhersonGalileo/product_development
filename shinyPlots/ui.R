library(shiny)
library(lubridate)




shinyUI(
  fluidPage(
    fluidRow(
      h1("Grafico Dinamico"),
      plotOutput("plot", brush = "plot_brush", dblclick = "plot_reset", click = "click", hover = "hover")
    ),
    
    fluidRow(
      h1("Tabla Dinamica"),
      dataTableOutput("tabla")
    )
  )
)