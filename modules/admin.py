"""
admin 用户操作 API
"""

from config import create_connection

if __name__ == '__main__':
    conn = create_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    for row in cursor.fetchall():
        print(row)
    cursor.close()
    conn.close()