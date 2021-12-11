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
  
  output$barplot_airplane<-renderPlot({
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
      res$label = factor(res$label, levels = month.abb)
      
      p<-ggplot(data=res, aes(x=label, y=y)) +
        geom_bar(stat="identity",fill=input$bar_color)+
        geom_text(aes(label=y), vjust=1.6, color="white", size=3.5)+
        labs(title="Cantidad de Vuelos por mes", 
             x="Mes", y = "Cantidad")+
        theme_minimal()
      
    } else {
      res <- res %>%
        mutate(label = x)
      
      p<-ggplot(data=res, aes(x=label, y=y)) +
        geom_bar(stat="identity", fill=input$bar_color)+
        geom_text(aes(label=y), vjust=1.6, color="white", size=3.5)+
        labs(title=paste0("Cantidad de Vuelos por dia ",input$month), 
             x="dia", y = "Cantidad")+
        theme_minimal()
    }
    
    p
  })
  
  
  output$barplot_top_airports<- renderPlot({
    top<-vuelos() %>%
      group_by(dest, dest_name) %>%
      tally() %>%
      collect() %>%
      arrange(desc(n)) %>%
      head(10) %>%
      arrange(dest_name) %>%
      mutate(dest_name = str_sub(dest_name, 1, 30)) %>%
      rename(
        x = dest,
        y = n,
        label = dest_name
      )
    
    
    
    p<-ggplot(data=top, aes(x=label, y=y,fill=label)) +
      geom_bar(stat="identity")+#, fill="steelblue"
      geom_text(aes(label=y), vjust=1.6, color="white", size=3.5)+
      labs(title="Top de Aereopuertos", 
           x="Aereopuerto", y = "Cantidad")+
      theme_minimal()
    p
    
  })
  

  observeEvent(input$bar_flighs_click,{
    
    
    if(round(input$bar_flighs_click$x)>0){
      clicked <- round(input$bar_flighs_click$x)
        if(input$month==30){
          new_df <- vuelos()%>%filter(month==clicked)
          updateTable(new_df)
        }else{
          new_df <- vuelos()%>%filter(month==input$month,day==clicked)
          updateTable(new_df)
        }
    }
 })
 
  
  
  updateTable<- function(new_df){
    output$details <- DT::renderDataTable({
      new_df
    })
  }
  
  output$details <- DT::renderDataTable({
    vuelos()
    
  })
  
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    
    airline   <- query[['airline']]
    color     <- query[['color']]
    mes       <- query[['month']]
    
    if(!is.null(airline)){
      updateSelectInput(session, 'airline', selected = airline)
    }
    
    if(!is.null(color)){
      updateSelectInput(session,'bar_color', selected=color)
    }
    
    if(!is.null(mes)){
      updateSelectInput(session,'month', selected=mes)
    }
    
  })
  
  observe({
    airline<- input$airline
    color <- input$bar_color
    mes <- input$month
    host_name <- session$clientData$url_hostname
    protocol <- session$clientData$url_protocol
    port <- session$clientData$url_port
    query <- paste('?','airline=', airline,'&color=',color,'&month=',mes,sep='')
    
    url <- paste(protocol, '//', host_name, ':', port,'/',query, sep = '')
    
    updateTextInput(session, 'url_param', value = url)
    
  })
  
  
  
})
