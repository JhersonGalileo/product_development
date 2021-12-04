library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)


shinyServer(function(input, output,session) { 
  
  selected <- reactiveVal(rep("blue", nrow(mtcars)))
  
  df_mtcars <- reactiveVal(mtcars)
  
  observeEvent(input$plot_brush, {
    brushed <- brushedPoints(mtcars, input$plot_brush, allRows = TRUE)$selected_
    
    tmp <- selected()
    
    i = 1
    for (seleccionado in brushed){
      if (seleccionado){
        tmp[i] <- "green"
      }
      i = i+1
    }
    
    
    #selected(brushed | selected())
    selected(tmp)
    df_mtcars <- df_mtcars(brushedPoints(mtcars, input$plot_brush))
  })
  
  observeEvent(input$click,{
    click <- nearPoints(mtcars, input$click, allRows = TRUE)$selected_
    tmp <- selected()
    
    i = 1
    for (seleccionado in click){
      if (seleccionado){
        tmp[i] <- "green"
      }
      i = i+1
    }
    
    selected(tmp)
    
    df_mtcars <- df_mtcars(nearPoints(mtcars, input$click))
  })
  
  observeEvent(input$hover,{
    click <- nearPoints(mtcars, input$hover, allRows = TRUE)$selected_
    tmp <- selected()
    
    i = 1
    for (seleccionado in click){
      if (seleccionado){
        tmp[i] <- "gray"
      }
      i = i+1
    }
    
    selected(tmp)
  })
  
  observeEvent(input$plot_reset, {
    selected(rep("blue", nrow(mtcars)))
  })
  
  output$plot <- renderPlot({
    mtcars$sel <- selected()
    ggplot(mtcars, aes(wt, mpg)) + 
      geom_point(colour = mtcars$sel)
        
  }, res = 96)
  
  
  
  output$tabla <- renderDataTable({
    df_mtcars()
    #brushed <- brushedPoints(mtcars, input$plot_brush)
    #brushed
  })
  
  

  
})
