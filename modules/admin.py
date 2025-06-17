
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

def test():
    conn = create_connection()
    cursor = conn.cursor()
    sql_query = f"EXEC {'sp_get_course_detail_public'} ?"
    cursor.execute(sql_query, 'c0001')
    
    result_set_count = 1
    
    while True:
        if not cursor.description:
            break 

        print(f"\n--- 正在处理第 {result_set_count} 个结果集 ---")
        columns = [column[0] for column in cursor.description]
        print(f"列名: {columns}")
        rows = cursor.fetchall()
        if not rows:
            print("这个结果集没有返回任何行。")
        else:
            for row in rows:
                print(row)
        if not cursor.nextset():
            break     
        result_set_count += 1
