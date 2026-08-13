import pandas as pd
from sqlalchemy import create_engine
import os

# Ruta donde tienes guardados tus archivos
ruta_carpeta = r"C:\Users\Luis\Documents\PROYECTOS SQL\RETAIL\excel"

archivo_train = os.path.join(ruta_carpeta, "Train-Set.csv")
archivo_test = os.path.join(ruta_carpeta, "Test-Set.csv")

print("Leyendo archivos CSV...")
df_train = pd.read_csv(archivo_train)
df_test = pd.read_csv(archivo_test)

# Configura tu servidor y el nombre de la base de datos que acabas de crear
server = 'localhost'       # O tu instancia local de SQL Server
database = 'RetailDB'      # El nombre que le pusiste al crear la BD

connection_string = f"mssql+pyodbc://@{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
engine = create_engine(connection_string)

print("Subiendo tablas crudas a SQL Server...")

df_train.to_sql('Staging_Train_Raw', con=engine, if_exists='replace', index=False)
df_test.to_sql('Staging_Test_Raw', con=engine, if_exists='replace', index=False)

print("¡Listo! Tablas subidas con éxito.")