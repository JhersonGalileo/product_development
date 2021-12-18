import streamlit as st
import numpy as np
import pandas as pd
from sqlalchemy import create_engine
import logging
import datetime
#import pydeck as pdk

import plotly.express as px
import plotly.graph_objects as go


engine = create_engine("mysql+mysqldb://jsazo:sazo30@db/covit")

conn = engine.connect()

query = "select pc.id_province_fk,pc.full_date,  pc.num_cases , pc.num_cases_acum from positive_cases pc"


#bajamos a memoria los casos confirmados
@st.cache(allow_output_mutation=True)
def cargar_positivos():
    #try:
    #query = "select pc.id_province_fk,pc.full_date,  pc.num_cases , pc.num_cases_acum from positive_cases pc"
    query = """select pc.full_date, p.longitude , p.latitude , pc.num_cases, pc.num_cases_acum, p.id_province 
                 from positive_cases pc inner join province p on p.id_province =pc.id_province_fk """
    res = conn.execute(query)
    #df = pd.DataFrame(res.fetchall(), columns=['provincia', 'date_time', 'num_cases', 'num_cases_acum'])
    df = pd.DataFrame(res.fetchall(), columns=['date_time', 'lon', 'lat', 'num_cases','num_cases_acum','id_provincia'])
    return df


#bajamos a memoria los casos fallecidos
@st.cache(allow_output_mutation=True)
def cargar_muertos():
    #try:
    #query = "select pc.id_province_fk,pc.full_date,  pc.num_cases , pc.num_cases_acum from death_cases pc"
    query = """select pc.full_date, p.longitude , p.latitude , pc.num_cases, pc.num_cases_acum, p.id_province 
                from death_cases pc inner join province p on p.id_province =pc.id_province_fk """
    res = conn.execute(query)
    #df = pd.DataFrame(res.fetchall(), columns=['provincia', 'date_time', 'num_cases', 'num_cases_acum'])
    df = pd.DataFrame(res.fetchall(), columns=['date_time', 'lon', 'lat', 'num_cases','num_cases_acum','id_provincia'])
    return df

#bajamos a memoria los casos recuperados
@st.cache(allow_output_mutation=True)
def cargar_recuperados():
    #try:
    #query = "select pc.id_province_fk,pc.full_date,  pc.num_cases , pc.num_cases_acum from recovered_cases pc"
    query = """select pc.full_date, p.longitude , p.latitude , pc.num_cases, pc.num_cases_acum, p.id_province 
                from recovered_cases pc inner join province p on p.id_province =pc.id_province_fk """
    res = conn.execute(query)
    #df = pd.DataFrame(res.fetchall(), columns=['provincia', 'date_time', 'num_cases', 'num_cases_acum'])
    df = pd.DataFrame(res.fetchall(), columns=['date_time', 'lon', 'lat', 'num_cases','num_cases_acum','id_provincia'])
    return df


#bajamos a memoria los paises
@st.cache(allow_output_mutation=True)
def cargar_paises():
    #try:
    query = "select c.id_country, c.name from country c"
    res = conn.execute(query)
    df = pd.DataFrame(res.fetchall(), columns=['id_country', 'country'])
    return df

#bajamos a memoria las provincias
@st.cache(allow_output_mutation=True)
def cargar_provincias():
    #try:
    query = "select * from province"
    res = conn.execute(query)
    df = pd.DataFrame(res.fetchall(), columns=['id_province', 'provincia','id_country','lon','lat'])
    return df

#bajamos totales a memoria
@st.cache(allow_output_mutation=True)
def cargar_totales():
    #try:
    query = """select pc.full_date , sum(pc.num_cases) as confirmed, sum(dc.num_cases) as deaths,sum(rc.num_cases) as recovered from positive_cases pc 
                inner join death_cases dc on pc.id_province_fk = dc.id_province_fk and pc.full_date = dc.full_date 
                inner join recovered_cases rc on pc.id_province_fk = rc.id_province_fk and pc.full_date = rc.full_date 
                group by pc.full_date """
    res = conn.execute(query)
    df = pd.DataFrame(res.fetchall(), columns=['date_time', 'confirmados','fallecidos','recuperados'])
    return df


@st.cache(allow_output_mutation=True)
def cargar_totales_por_pais():
    query = """
            select pc.full_date ,c.name as country,sum(pc.num_cases) as confirmed, sum(dc.num_cases) as deaths,sum(rc.num_cases) as recovered from positive_cases pc 
                    inner join death_cases dc on pc.id_province_fk = dc.id_province_fk and pc.full_date = dc.full_date 
                    inner join recovered_cases rc on pc.id_province_fk = rc.id_province_fk and pc.full_date = rc.full_date 
                    inner join province p ON p.id_province = pc.id_province_fk 
                    inner join country c on c.id_country =p.id_country_fk 
                    group by pc.full_date,c.name    
           """
    res = conn.execute(query)
    df = pd.DataFrame(res.fetchall(), columns=['date_time', 'country','confirmados','fallecidos','recuperados'])
    return df



ini=  st.sidebar.date_input(
        "Fecha Inicio",
        datetime.date(2020, 1, 22))

fin= st.sidebar.date_input(
     "Fecha Fin",
     datetime.datetime.today())

positives = (cargar_positivos()
            .loc[lambda df: (df.date_time>=ini)&(df.date_time<=fin)]
            .loc[lambda df: df.num_cases >0]
            )
deaths = (cargar_muertos()
            .loc[lambda df: (df.date_time>=ini)&(df.date_time<=fin)]
         )
recovered = (cargar_recuperados()
                .loc[lambda df: (df.date_time>=ini)&(df.date_time<=fin)]
            )

countries = cargar_paises().set_index("country")
provincias = cargar_provincias()
totales = (cargar_totales()
            .loc[lambda df: (df.date_time>=ini)&(df.date_time<=fin)]
          )

total_por_pais = (
                    cargar_totales_por_pais()
                        .loc[lambda df: (df.date_time>=ini)&(df.date_time<=fin)]
                )

st.title("Dashboard de estadisticas del COVID")

#vamos a plotear un linebar
"""
##Totales Globales
"""
fig = px.line(totales, x="date_time", y=["confirmados","fallecidos","recuperados"],title="Casos acumulados por fecha")#, color='confirmados'
st.plotly_chart(fig)

if st.checkbox('Mostrar Tabla Totales'):
    totales


"""
## Totales confirmados por pais y fecha

"""

countries = st.multiselect(
        "Selecciona los paises", list(countries.index)
        )
if not countries:
        st.error("Selecciona un pais")
else:
    new_list = [str(coun) for coun in countries]
    #confirmados
    aux = total_por_pais[total_por_pais["country"].isin(new_list)]
    fig = px.line(aux, x='date_time', y='confirmados', color='country', symbol="country")
    st.plotly_chart(fig)
    
    #muertes
    """
    ## Muertes por covid
    """
    aux_2 = total_por_pais[total_por_pais["country"].isin(new_list)]
    fig2 = px.line(aux, x='date_time', y='fallecidos', color='country', symbol="country")
    st.plotly_chart(fig2)

    #recuperados
    """
    ## Recuperados por covid
    """
    aux_3 = total_por_pais[total_por_pais["country"].isin(new_list)]
    fig3 = px.line(aux, x='date_time', y='recuperados', color='country', symbol="country")
    st.plotly_chart(fig3)


"""
## Mapa de Disperción por Fecha del COVID
"""
#st.map(provincias)
st.map(positives)

