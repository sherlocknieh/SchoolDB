# 数据库连接配置
import pyodbc

CONFIG = {
    'driver': 'ODBC Driver 17 for SQL Server',
    'server': '华硕天选',
    'database': 'SchoolDB',
    'username': 'sa',
    'password': '123456',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes'
}

def create_connection():
    """
    创建 SQL Server 连接
    """
    conn_str = (
        f'DRIVER={CONFIG['driver']};'
        f'SERVER={CONFIG["server"]};'
        f'DATABASE={CONFIG["database"]};'
        f'UID={CONFIG["username"]};'
        f'PWD={CONFIG["password"]};'
        f'Trusted_Connection={CONFIG["trusted_connection"]};'
        f'TrustServerCertificate={CONFIG["trust_server_certificate"]}'
    )
    return pyodbc.connect(conn_str)


if __name__ == '__main__':
    conn = create_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    for row in cursor.fetchall():
        print(row)
    cursor.close()
    conn.close()