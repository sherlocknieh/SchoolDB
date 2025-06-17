import pyodbc

server_name = '华硕天选' 
database_name = 'SchoolDB' 
stored_proc_name = 'sp_get_course_detail_public'
course_id_param = 'c0001'

conn_str = (
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={server_name};'
    f'DATABASE={database_name};'
    f'Trusted_Connection=yes;'
)


cnxn = pyodbc.connect(conn_str)
cursor = cnxn.cursor()
    
sql_query = f"EXEC {stored_proc_name} ?"
cursor.execute(sql_query, course_id_param)
    

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