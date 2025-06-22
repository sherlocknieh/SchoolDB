import pyodbc
from flask import Flask, request, session, render_template, redirect, url_for, jsonify

from modules.config import execute_query     # 数据库查询函数: 自动连接数据库、执行查询、返回结果


app = Flask(__name__)
app.template_folder = 'pages'  # 设置模板文件目录
app.static_folder = 'pages/static'  # 设置静态文件目录
app.secret_key = 'session_secret_key'  # session 密钥


# 主页面: 默认显示登录页面
@app.route('/', methods=['GET', 'POST'])
@app.route('/login', methods=['GET', 'POST'])
def login():
    error_message = ''
    if request.method == 'POST':
        input_username = request.form.get('username')
        input_password = request.form.get('password')
        input_role = request.form.get('role')
        try:
            result = execute_query(
                f"SELECT username, password, role"
                f" FROM Users"
                f" WHERE username = '{input_username}'"
                f" AND role = '{input_role}'"
            )
            if not result:
                error_message = '用户不存在'
            else:
                data = result[0]
                if data['password'] != input_password:
                    error_message = '密码错误'
                else:
                    session['user'] = data['username']
                    session['role'] = data['role']
                    print(f"[INFO] 用户 {session['user']} 登录成功")
                    return jsonify({"redirect_url": url_for(f"{data['role']}")})
        except pyodbc.ProgrammingError as pe:
            error_message = '数据库错误，请联系管理员'
            print(f"[SQL 编程错误] {pe}")
        except pyodbc.Error as e:
            error_message = '数据库查询失败，请稍后再试'
            print(f"[数据库错误] {e}")
        return jsonify({'error_message': error_message})
    return render_template('login.html', error_message=error_message)


# 登出按钮: 清除 session, 回到登录页面
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


# 学生页面
@app.route('/student', methods=['GET', 'POST'])
def student():
    if session.get('role') != 'student':    # 如果未登录
        return redirect(url_for('login'))   # 回到登录页面
    
    # 登录成功
    # 查询事务写在这里
    results = []
    if request.method == 'POST':
        cmd = request.form.get('cmd')
        from modules.student import student_action   # 学生数据库操作函数
        results = student_action(cmd)  # 调用 modules/student.py 中的数据库操作函数进行查询

    return render_template('student.html', user=session['user'], results=results) # 把查询结果显示在学生页面


# 教师页面
@app.route('/teacher', methods=['GET', 'POST'])
def teacher():
    if session.get('role') != 'teacher':    # 如果未登录
        return redirect(url_for('login'))   # 回到登录页面
    
    # 登录成功
    from modules.teacher import teacher_action   # 教师数据库操作函数
    # 查询事务写在这里
    

    return render_template('teacher.html', user=session['user'])  # 显示教师页面


# 管理员页面
@app.route('/admin', methods=['GET', 'POST'])
def admin():
    print(f"[INFO] 管理员 {session['user']} 登录成功")
    if session.get('role') != 'admin':
        return redirect(url_for('login'))
    
    # 登录成功
    from modules.admin import admin_action       # 管理员数据库操作函数
    # 查询事务写在这里
    admin_action()
    return render_template('admin.html', user=session['user'])


if __name__ == '__main__':
    app.run(debug=True)
