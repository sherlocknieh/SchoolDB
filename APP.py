from flask import Flask, render_template, request, redirect, url_for, session
from modules.config import CONFIG   # SQL Server 连接信息
import pyodbc



app = Flask(__name__)

"""
登录管理:
默认进入登录页面
登录成功后进入对应角色的页面
退出登录后回到登录页面
"""

app.secret_key = 'session_secret_key'  # session 密钥



def get_db_connection():
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
    conn = pyodbc.connect(conn_str)
    if conn:
        return conn
    else:
        print('连接失败')
        return None

 
@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        input_username = request.form.get('username')
        input_password = request.form.get('password')
        input_role = request.form.get('role')

        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute(
                "SELECT username, password, role FROM users WHERE username = ? AND role = ?",
                (input_username, input_role)
            )
            row = cursor.fetchone()
        
            conn.close()

            if row and row.password == input_password:
                session['user'] = row.username
                session['role'] = row.role
                return redirect(url_for(f'{row.role}'))
            else:
                error = '用户名、密码或身份错误'
        except pyodbc.ProgrammingError as pe:
            error = '数据库结构错误（如表或列不存在），请联系管理员'
            print(f"[SQL 编程错误] {pe}")
        except pyodbc.Error as e:
            error = '数据库查询失败，请稍后再试'
            print(f"[数据库错误] {e}")
            
    return render_template('login.html', error=error)

@app.route('/teacher')
def teacher():
    if session.get('role') != 'teacher':
        return redirect(url_for('login'))
    return render_template('teacher.html', user=session['user'])

@app.route('/student')
def student():
    if session.get('role') != 'student':
        return redirect(url_for('login'))
    return render_template('student.html', user=session['user'])

@app.route('/admin')
def admin():
    if session.get('role') != 'admin':
        return redirect(url_for('login'))
    return render_template('admin.html', user=session['user'])

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
def index():
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True)
