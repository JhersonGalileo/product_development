library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)


shinyServer(function(input, output,session) { 
  
  cars <- mtcars
  cars$color <-  sample(c("gray"),length(mtcars$mpg), replace = T)

  
  observeEvent(input$clk, {
    #leafletProxy("mymap") %>% clearPopups()
    print("click")
    df<-nearPoints(mtcars, input$clk, xvar='wt',yvar='mpg')
    if (dim(df)[1]>0){
      print(paste0(df$wt,", ",df$mpg))
     # output$plot_click_options <- renderPlot({
      #  plot(cars$wt, cars$mpg, ylab = 'Millas por galon', xlab = 'wt',col="red")#cars$color)
     # })
    }
    
    
  })
  
  
  

  output$grafica_base_r <- renderPlot({
      plot(mtcars$wt,mtcars$mpg,xlab = 'wt',ylab = 'Millas por Galon')
  })
  
  output$grafica_ggplot <- renderPlot({
      diamonds%>%
      ggplot(aes(x=carat, y=price, color=color))+
          geom_point()+
          ylab('price')+
          xlab('Kilates')+
          ggtitle('Precio de diamantes')
  })
  
  
  output$plot_click_options <- renderPlot({
      plot(cars$wt, cars$mpg, ylab = 'Millas por galon', xlab = 'wt',col=cars$color)
      
      df <- nearPoints(mtcars, input$clk, xvar='wt',yvar='mpg')
      #if (dim(df)[1]>0){
      #  validar_puntos(df$wt,df$mpg)
      #}
      
    #print(df)
  })
  
  
  output$output_1 <- renderPrint({
      rbind(
            c(input$clk$x,input$clk$y),
            c(input$dclik$x,input$dclik$y),
            c(input$mouse_hover$x,input$mouse_hover$y),
            c(input$mouse_brush$xmin, input$mouse_brush$ymin),
            c(input$mouse_brush$xmax, input$mouse_brush$ymax)
            )
  })
  
  
  output$mtcars_tbl<- DT::renderDataTable({
      #df <- nearPoints(mtcars, input$mouse_hover, xvar='wt',yvar='mpg')
      df <- brushedPoints(mtcars, input$mouse_brush, xvar='wt',yvar='mpg')
      df
      
  })
  
  validar_puntos <- function(x,y){
    print(paste0("Parametros",",",x,",",y))
    
    cars['color'] <- ifelse((as.numeric(cars$wt)==x) & (as.numeric(cars$mpg==y)),'green','gray') 
    print(cars$color)
    
    output$plot_click_options <- renderPlot({
      plot(cars$wt, cars$mpg, ylab = 'Millas por galon', xlab = 'wt',col=cars$color)
    })
  }
    
})