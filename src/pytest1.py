import psycopg2
import pandas as pd
import math

conn = psycopg2.connect(
    host="localhost",
    port="5434",
    database="sdad",
    user="ads7fg",
    password="Iwnftp$2")

cur = conn.cursor()

cur.execute("SELECT appr_baths, bedrooms, living_sq_ft \
             FROM corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog TABLESAMPLE SYSTEM(0.01) \
             WHERE living_sq_ft is not null")
          
rows = cur.fetchall()

cur.close()
conn.close()


# Extract the column names
col_names = []
for elt in cur.description:
    col_names.append(elt[0])

rows_pd = pd.DataFrame(rows, columns=col_names)

cols = rows_pd.columns

rows_pd[cols] = rows_pd[cols].apply(pd.to_numeric, errors='coerce')

print(rows_pd.head())


import matplotlib.pyplot as plt
plt.style.use('seaborn-whitegrid')
import numpy as np

x = np.linspace(0, 10, 30)
y = np.sin(x)

plt.plot(x, y, 'o', color='black')
plt.show()

