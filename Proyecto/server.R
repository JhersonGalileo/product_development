library(shiny)

shinyServer(function(input,output,session){
  
  vuelos <- reactive({
    res <- flights %>%filter(carrier==input$airline) %>%
      left_join(airlines, by = "carrier") %>%
      rename(airline = name) %>%
      left_join(airports, by = c("origin" = "faa")) %>%
      rename(origin_name = name) %>%
      select(-lat, -lon, -alt, -tz, -dst) %>%
      left_join(airports, by = c("dest" = "faa")) %>%
      rename(dest_name = name)
    
    if(input$month!= 30){
      res <- filter(res, month== input$month)
    }
    
    res
  })
  
  
  #mostramos los vuelos totales
  output$vuelos_totales <- renderValueBox({
    vuelos_tot <- vuelos() %>%tally()%>%pull()%>%as.integer()%>%valueBox(subtitle = "Numbero de Vuelos", color ='aqua',icon = icon("plane"))
    vuelos_tot
  })
  
  #promedio de vuelos
  output$por_dia <- renderValueBox({
    per_day <-vuelos() %>% group_by(day, month) %>%
      tally() %>%
      ungroup() %>%
      summarise(avg = mean(n)) %>%
      pull(avg) %>%
      round() %>%
      valueBox(subtitle = "Promedio de Vuelos por dia", color ='light-blue',icon = icon("chart-pie"))
    per_day
  })
  
  output$vuelos_tarde <- renderValueBox({
    tarde <- vuelos()%>%filter(!is.na(dep_delay)) %>%
      mutate(delayed = ifelse(dep_delay >= 15, 1, 0)) %>%
      summarise(
        delays = sum(delayed),
        total = n()
      ) %>%
      mutate(percent = (delays / total) * 100) %>%
      pull() %>%
      round() %>%
      paste0("%") %>%
      valueBox(subtitle = "Vuelos Tarde", color ='red',icon = icon("plane-slash"))
    
  })
 
})
