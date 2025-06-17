import pyodbc
from flask import Flask, render_template, request, redirect, url_for, session

from modules.config import create_connection   # 数据库连接函数
from modules.teacher import teacher_action   # 教师数据库操作函数
from modules.student import student_action   # 学生数据库操作函数
from modules.admin import admin_action     # 管理员数据库操作函数


app = Flask(__name__)



"""登录管理:
默认进入登录页面
登录成功后进入对应角色的页面
退出登录后回到登录页面
"""
app.secret_key = 'session_secret_key'  # session 密钥

@app.route('/')
def index():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        input_username = request.form.get('username')
        input_password = request.form.get('password')
        input_role = request.form.get('role')

        try:
            conn = create_connection()
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
            error = '数据库结构错误，请联系管理员'
            print(f"[SQL 编程错误] {pe}")
        except pyodbc.Error as e:
            error = '数据库查询失败，请稍后再试'
            print(f"[数据库错误] {e}")
    return render_template('login.html', error=error)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/teacher')
def teacher():
    if session.get('role') != 'teacher':    # 如果未登录
        return redirect(url_for('login'))   # 回到登录页面
    return render_template('teacher.html', user=session['user'])  # 显示教师页面


@app.route('/student', methods=['GET', 'POST'])
def student():
    # if session.get('role') != 'student':
    #     return redirect(url_for('login'))
    # return render_template('student.html', user=session['user'])
    # 暂时跳过登录逻辑，直接进入学生页面

    results = student_action()  # 调用 modules/student.py 中的数据库操作函数进行查询

    return render_template('student.html', results=results) # 把查询结果显示在学生页面


@app.route('/admin')
def admin():
    if session.get('role') != 'admin':
        return redirect(url_for('login'))
    return render_template('admin.html', user=session['user'])


if __name__ == '__main__':
    app.run(debug=True)
