import streamlit as st
import numpy as np
import pandas as pd 


st.title("This is my first app from here!")
x=4

st.write(x, 'square is',x**4)

x, 'square is',x**4 #imprime en pantalla pero es confuso ver


st.write(pd.DataFrame({
    'Columna A':['A','B','C','D','E'],
    'Columna B':[1,2,3,4,5]
}))


#OTRA FORMA DE ESCRIBIR EN TEXTO ES:

"""
# Title: This is a Tittle tag
This is another example for dataframes
"""
df = pd.DataFrame({
    'Columna A':['A','B','C','D','E'],
    'Columna B':[1,2,3,4,5]
})

df

"""
## Show me some graphs
"""

df_to_plot = pd.DataFrame(
    np.random.randn(20,3), columns =['Column A','Column B','Column C']
)
st.line_chart(df_to_plot)


"""
## Let´s plot a map!
"""

df_lat_long = pd.DataFrame(
    np.random.randn(1000,2)/[50,50] + [37.76, -122.4],
    columns=['lat','lon']
)

st.map(df_lat_long)

if st.checkbox('show dataframe'):
    df_lat_long


x = st.slider('Select a value for X',min_value=1,max_value=100, value=4)
y = st.slider('Select powder for X', min_value=0,max_value=5,value=2)
st.write(x,'pow ',y, '=', x**y)

def test():
    st.write("Funcion ejecutada")


"""
## What about options
"""
option_list = range(1,10)
options = st.selectbox('Which number do you like best?',option_list, on_change= test)
st.write('Your favorite number is: ',options)


"""
## HOw about a progress bar
"""

import time
label = st.empty()

progress_bar = st.progress(0)

for i in range(100):
    label.text("The value is: {}".format(i))
    progress_bar.progress(i)
    #time.sleep(0.125)

'The wait is done!'


st.sidebar.write("THIS IS A SIDE BAR")

option_side = st.sidebar.selectbox("Which number number do you like best?", option_list)
st.sidebar.write('The selection is: ',option_side)

st.write('another slider')
another_slider = st.sidebar.slider('Select Range:',0.5,100.0,(25.0,75.0))
st.sidebar.slider('Ejemplo',another_slider)


