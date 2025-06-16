# 测试 pyodbc 库访问 SQL Server 数据库

import pyodbc

DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER = 'localhost\\SQLEXPRESS'
USERNAME = 'sa'
PASSWORD = '123456'
DATABASE = 'School'


def test():
    conn = pyodbc.connect(
        driver=DRIVER,
        server=SERVER,
        username=USERNAME,
        password=PASSWORD,
        database=DATABASE,
        trusted_connection='yes',
        TrustServerCertificate="yes"
    )

    SQL_QUERY = """SELECT Sno,Cno FROM SC"""

    cursor = conn.cursor()       # 创建游标
    cursor.execute(SQL_QUERY)    # 执行SQL查询
    records = cursor.fetchall()  # 获取查询结果

    # 打印查询结果
    for r in records:
        print(f"Sno: {r[0]} Cno: {r[1]}")


    cursor.close()    # 关闭游标
    conn.close()      # 关闭连接

if __name__ == '__main__':
    test()