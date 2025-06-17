
if __name__ == '__main__':
    from config import create_connection
else:
    from .config import create_connection



""" 管理员用户操作 API
接收来自网页的命令
解析命令并执行相应的操作
返回结果
"""


def admin_action(cmd):
    """
    管理员命令解析器
    """
    conn = create_connection()
    cursor = conn.cursor()


    cursor.execute("SELECT * FROM users")
    for row in cursor.fetchall():
        print(row)

    
    cursor.close()
    conn.close()


