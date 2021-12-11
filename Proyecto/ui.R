library(shiny)
library(shinydashboard)
library(dplyr)
library(rlang)
library(stringr)
library(nycflights13)
library(DT)
library(r2d3)
library(purrr)


#lista de aereolineas
lista_aereo = airlines %>%collect() %>%split(.$name) %>%map(~ .$carrier)

lista_months <- as.list(1:12)%>%set_names(month.name)
lista_months$All <- 30

dashboardPage(
  dashboardHeader(title = "Dashboard de Vuelos"),
  dashboardSidebar(
    selectInput(
      inputId = "airline",
      label = "Aereolinea:",
      choices = lista_aereo,
      selectize = FALSE
    ),
    selectInput(
      inputId = "month",
      label = "Mes:",
      choices = lista_months,
      selected = 30,
      size = 13,
      selectize = FALSE
    ),
    selectInput(
      inputId = "bar_color",
      label ="Seccione color:",
      choices = c("aquamarine","blue","blueviolet","darkgray","chocolate"), 
      selected="aquamarine"
    )
  ),
  dashboardBody(
    tabsetPanel(
      id = "tabs",
      tabPanel(
        title = "Panel de vuelos",
        value = "pag_1",
        fluidRow(
          valueBoxOutput("vuelos_totales"),
          valueBoxOutput("por_dia"),
          valueBoxOutput("vuelos_tarde")
        ),
        fluidRow(),
        fluidRow(
          column(
            width = 6,
            plotOutput(outputId = "barplot_airplane", click = "bar_flighs_click")
          ),
          column(
            width = 6,
            plotOutput(outputId = "barplot_top_airports")
          )
        ),
        fluidRow(
          column(width = 12,
                 dataTableOutput("details")
          )
        )
      )
    )
  )
)
