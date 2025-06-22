# 数据库连接配置
import pyodbc


# 靠底部的变量有效, 使用时交换一下顺序即可
server_name = '华硕天选'
server_name = 'localhost\\SQLEXPRESS'


def create_connection(database='SchoolDB'):
    print(f'[INFO] 服务器: {server_name}')
    print(f'[INFO] 数据库: {database}')
    print('[INFO] 正在连接...', end='')
    conn_str = (
        f'DATABASE={database};'
        f'SERVER={server_name};'
        f'Trusted_Connection=yes;'
        f'DRIVER=ODBC Driver 17 for SQL Server;'
    )
    conn = pyodbc.connect(conn_str)
    print(f'连接成功')
    return conn


def execute_query(query, database='SchoolDB'):
    conn = create_connection(database)
    cursor = conn.cursor()

    print(f'[INFO] 正在执行查询: {query}')
    cursor.execute(query)


    columns = [desc[0] for desc in cursor.description]    # 获取表头
    rows = cursor.fetchall()                              # 获取所有行
    result = [dict(zip(columns, row)) for row in rows]    # 转换为字典列表
    cursor.close()
    conn.close()
    print(f'[INFO] 查询完成...连接已关闭')

    # 返回结果
    return result


if __name__ == '__main__':
    # 测试查询

    input_username = 'student1'
    input_role = 'Student'

    result = execute_query(
        f"SELECT username, password, role"
        f" FROM Users"
        f" WHERE username = '{input_username}'"
        f" AND role = '{input_role}'"
    )
    # 打印结果
    print(f'[INFO] 查询结果: ')
    [print(row) for row in result]
    
    # 格式化输出
    import json
    print('[INFO] 格式化输出: ')
    print(json.dumps(result, indent=4))