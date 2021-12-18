import os

from airflow import DAG
from airflow.contrib.hooks.fs_hook import FSHook
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.hooks.mysql_hook import MySqlHook
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
from structlog import get_logger
from datetime import datetime
import pandas as pd

logger = get_logger()



#queries para inserciones
query_cases = """insert into {}(day,month,year,full_date,id_province_fk,num_cases,num_cases_acum)
                        values({},{},{},'{}',{},{},{})
                    """
query_country_province = "insert into province(name,id_country_fk,latitude,longitude) values('{}',{},{},{})"

#diccionarios 
DICT_COUNTRY = {}
DICT_PROVINCE = {}


dag = DAG('etl_dag_1', description='This is an implementation to load covid file cases',
          default_args={
              'owner': 'jherson.sazo',
              'depends_on_past': False,
              'max_active_runs': 10,
              'start_date': days_ago(2)
          },
          schedule_interval='0 2 * * *',
          catchup=False)


sensor_confirmed = FileSensor(task_id='confirmed_sensor_file',
                    dag=dag,
                    fs_conn_id='fs_default',
                    filepath='time_series_covid19_confirmed_global.csv',
                    poke_interval=15,
                    timeout=150
                    )

sensor_deadth = FileSensor(task_id='death_sensor_file',
                    dag=dag,
                    fs_conn_id='fs_default',
                    filepath='time_series_covid19_deaths_global.csv',
                    poke_interval=15,
                    timeout=150
                )

sensor_recovered = FileSensor(task_id='recover_sensor_file',
                    dag=dag,
                    fs_conn_id='fs_default',
                    filepath='time_series_covid19_recovered_global.csv',
                    poke_interval=15,
                    timeout=150
                )


def process_confirmed_file():
    logger.info("###process_confirmed_file###")
    
    file_path = f"{FSHook('fs_default').get_path()}/time_series_covid19_confirmed_global.csv"
    
    connection = MySqlHook('mysql_default').get_sqlalchemy_engine()

    df = pd.read_csv(file_path)
    
    df = limpiar_datos(df)
    df = df.iloc[:,0:25]
    paises = df['Country/Region'].unique()
    pais_pov = df[['Country/Region','Province/State','Lat','Long']]
   
    
    with connection.begin() as transaction:

        columnas= df.columns.values
        columnas = columnas[4:]

        insertar_paises(paises,transaction)
        cargar_paises_a_diccionario(transaction)
        
        insertar_pais_provincia(pais_pov,transaction)
        cargar_provincias_al_diccionario(transaction)

        insertar_registros(df,columnas,'positive_cases',transaction)

        #transaction.execute('DELETE FROM test.sales WHERE 1=1')

        #df.to_sql('sales',con=transaction, schema='test',if_exists='append', index=False)
    
    logger.info(f'Rows Inserted {len(df.index)}')
    os.remove(file_path)
    logger.info(f"File {file_path} was removed")
    #print(df)


def process_death_file():
    logger.info("###process_death_file###")
    
    file_path = f"{FSHook('fs_default').get_path()}/time_series_covid19_deaths_global.csv"
    
    connection = MySqlHook('mysql_default').get_sqlalchemy_engine()

    df = pd.read_csv(file_path)
    df = limpiar_datos(df)
    df = df.iloc[:,0:25]
    
    
    with connection.begin() as transaction:

        columnas= df.columns.values
        columnas = columnas[4:]

        insertar_registros(df,columnas,'death_cases',transaction)

    
    logger.info(f'Rows Inserted {len(df.index)}')
    os.remove(file_path)
    logger.info(f"File {file_path} was removed")



def process_recovered_file():
    logger.info("###process_recovered_file###")
    
    file_path = f"{FSHook('fs_default').get_path()}/time_series_covid19_recovered_global.csv"
    
    connection = MySqlHook('mysql_default').get_sqlalchemy_engine()

    df = pd.read_csv(file_path)
    df = limpiar_datos(df)
    df = df.iloc[:,0:25]
    
    
    with connection.begin() as transaction:

        columnas= df.columns.values
        columnas = columnas[4:]

        insertar_registros(df,columnas,'recovered_cases',transaction)

    
    logger.info(f'Rows Inserted {len(df.index)}')
    os.remove(file_path)
    logger.info(f"File {file_path} was removed")


process_file_operator = PythonOperator(
    task_id='process_file',
    dag=dag,
    python_callable=process_confirmed_file
)


process_file_death = PythonOperator(
    task_id='process_file_death',
    dag=dag,
    python_callable=process_death_file
)


process_file_recovered = PythonOperator(
    task_id='process_file_recovered',
    dag=dag,
    python_callable=process_recovered_file
)


#metodos propios
def insertar_paises(row,conn):
    logger.info("###insertar_paises###")
    #res = conn.execute("SELECT * from country c").fetchall()
    
    for country in row:
        try:
            #country = country.replace("'","").strip()
            query = f"insert into country(name) values ('{country}')"
            conn.execute(query)
        except Exception as error:
            logger.error(f"Error en insertar el pais {country}, error {error}")

def cargar_paises_a_diccionario(conn):
    logger.info("***cargar_paises_a_diccionario***")
    
    global DICT_COUNTRY

    query ='select c.id_country, c.name from country c'
    lc = leer_datos_db(query,conn)
    lc.set_index('name', inplace=True)
    DICT_COUNTRY = lc.to_dict()
    DICT_COUNTRY = DICT_COUNTRY['id_country']

def cargar_provincias_al_diccionario(conn):
    logger.info("***cargar_provincias_al_diccionario***")
    
    global DICT_PROVINCE

    query ='select c.id_province, c.name from province c'
    lc = leer_datos_db(query,conn)
    lc.set_index('name', inplace=True)
    DICT_PROVINCE = lc.to_dict()
    DICT_PROVINCE = DICT_PROVINCE['id_province']

def insertar_pais_provincia(df,conn):
    logger.info("###insertar_pais_provincia###")
    for index,row in df.iterrows():
        
        country = row[0]
        pronvicia = row[1]
        lat = row[2]
        long = row[3]
        
        if pronvicia==0:
            pronvicia= country
        try:
            id_country = DICT_COUNTRY[country]

            query_aux = query_country_province.format(pronvicia,id_country,lat,long)#

            conn.execute(query_aux)
            logger.info(query_aux)
        except Exception as error:
            logger.error(error)

def leer_datos_db(query, conn):
    logger.info("###leer_datos_db###")
    try:
        df = pd.read_sql(query, conn)
        return df
    except (Exception) as error:
        logger.error("Error :{0}".format(error))
    
    return pd.DataFrame()

def limpiar_datos(df):
    logger.info("###limpiar_datos###")
    cond = (pd.isnull(df['Lat'])) | (pd.isnull(df['Long'])) | ((df['Lat'] == 0)&(df['Long']==0))
    
    index_to_delete = df[cond].index

    df.drop(index_to_delete , inplace=True)

    df = df.fillna(0)

    df['Country/Region'] = df['Country/Region'].apply(lambda x: replace_values(x))
    df['Province/State'] = df['Province/State'].apply(lambda x: replace_values(x))

    #df.to_csv('haber.csv')

    return df

def insertar_registros(df,fechas,tabla,conn):
    logger.info("###insertar_registros###")
    for index,fecha in enumerate(fechas):
        #for i in range(len(df.index)):

        date_time_obj = datetime.strptime(fecha, '%m/%d/%y')
        day = date_time_obj.day
        month= date_time_obj.month
        year = date_time_obj.year
        full_date = date_time_obj.strftime("%d/%m/%y")


        ant = 0
        for index, row in df.iterrows():
            try:
                province = row['Country/Region'] if row['Province/State']==0 else row['Province/State']
                id_province = DICT_PROVINCE[province]
                acum_cases = int(row[fecha])
                actual = abs(acum_cases-ant)
                
                query = query_cases.format(tabla,day,month,year,full_date,id_province,actual,acum_cases)

                conn.execute(query)
                
                ant = actual
                
            except Exception as error:
                logger.error("Error en el insert de confirmado: {}".format(error))
   
def replace_values(value):
    #logger.info("###replace_values###")
    if value !=0:
        return str(value).replace("'","").strip()
    return 0



sensor_confirmed>>process_file_operator>>sensor_deadth>>process_file_death>>sensor_recovered>>process_file_recovered