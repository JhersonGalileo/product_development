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
    actionLink("remove", "Remove detail tabs")
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
            d3Output("group_totals")
          ),
          column(
            width = 6,
            d3Output("top_airports")
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
