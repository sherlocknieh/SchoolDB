# 数据库连接配置
import pyodbc


# 靠底部的变量有效, 使用时交换一下顺序即可
server_name = 'localhost\\SQLEXPRESS'
server_name = '华硕天选'



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


def execute_query(query, *args):
    conn = None
    cursor = None

    print("**********")
    print(query)
    print(args)

    try:
        conn = create_connection()
        if conn is None:
            return []
        
        cursor = conn.cursor()
        if len(args) == 1 and isinstance(args[0], tuple):
            params = args[0] 
        else:
            params = args
        cursor.execute(query, params)
        if cursor.description is None:
            conn.commit()
            return []
        else:
            columns = [desc[0] for desc in cursor.description]
            rows = cursor.fetchall()
            print("result:")
            print(rows)
            conn.commit()
            if rows is None:
                return []
            
            result = [dict(zip(columns, row)) for row in rows]
            print(f'[INFO] 查询完成，返回 {len(result)} 条记录')
            return result
        
    except Exception as e:
        if conn:
            try:
                conn.rollback()
                print("[INFO] 事务已回滚")
            except:
                pass
        return [] 
        
    finally:
        try:
            if cursor:
                cursor.close()
                print("[INFO] 游标已关闭")
        except Exception as e:
            print(f"[WARNING] 关闭游标时出错: {str(e)}")
            
        try:
            if conn:
                conn.close()
        except Exception as e:
            print(f"[WARNING] 关闭连接时出错: {str(e)}")




if __name__ == '__main__':
    
    # 测试查询
    role = 'Student'
    result = execute_query(
        "SELECT username, password, role FROM Users WHERE role = ?",
        (role)
    )
    # 打印结果
    print(f'[INFO] 查询结果:')
    [print(row) for row in result]
    
    # 格式化打印
    import json
    print('[INFO] 格式化输出:')
    print(json.dumps(result, indent=4))