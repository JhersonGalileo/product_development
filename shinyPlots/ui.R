library(shiny)
library(lubridate)




shinyUI(
  fluidPage(
   
    titlePanel("Interacciones de usuario con graficas"),
    tabsetPanel(
      tabPanel('plot',
               h1('Graficas en Shiny'),
               plotOutput('grafica_base_r'),
               plotOutput('grafica_ggplot')
               ),
      tabPanel('Clicks en plots',
               plotOutput("plot_click_options",
                          click = 'clk',
                          dblclick = 'dclik',
                          hover='mouse_hover',
                          brush='mouse_brush'
                          ),
               verbatimTextOutput("output_1"),
               DT::dataTableOutput("mtcars_tbl")
             )
    )
    
  )
)