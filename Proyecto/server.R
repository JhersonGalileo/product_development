library(shiny)
library(ggplot2)

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
    vuelos_tot <- vuelos() %>%tally()%>%pull()%>%as.integer()%>%valueBox(subtitle = "Numero de Vuelos", color ='aqua',icon = icon("plane"))
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
  
  output$hist<-renderPlot({
    grouped <- ifelse(input$month != 30, expr(day), expr(month))
    
    res <- vuelos() %>%
      group_by(!!grouped) %>%
      tally() %>%
      collect() %>%
      mutate(
        y = n,
        x = !!grouped
      ) %>%
      select(x, y)
    
    if (input$month == 30) {
      res <- res %>%
        inner_join(
          tibble(x = 1:12, label = substr(month.name, 1, 3)),
          by = "x"
        )
    } else {
      res <- res %>%
        mutate(label = x)
    }
    
    p<-ggplot(data=res, aes(x=label, y=y)) +
      geom_bar(stat="identity", fill="steelblue")+
      geom_text(aes(label=y), vjust=1.6, color="white", size=3.5)
      theme_minimal()
    p
  })
 
})
