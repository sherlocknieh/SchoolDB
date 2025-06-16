import pyodbc
from flask import Flask, render_template


DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER = 'localhost\\SQLEXPRESS'
USERNAME = 'sa'
PASSWORD = '123456'
DATABASE = 'School'

conn = pyodbc.connect(
        driver=DRIVER,
        server=SERVER,
        username=USERNAME,
        password=PASSWORD,
        database=DATABASE,
        trusted_connection='yes',
        TrustServerCertificate="yes"
    )

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('login.html')

if __name__ == '__main__':
    app.run(debug=True)