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
                f"SELECT user_id, username, password, role"
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
                    session['user_id'] = data['user_id']
                    #print(f"[INFO] 用户 {session['user']} 登录成功")
                    return jsonify({"redirect_url": url_for(f"{data['role']}")})
        except pyodbc.ProgrammingError as pe:
            error_message = '数据库错误，请联系管理员'
            print(f"[SQL 编程错误] {pe}")
        except pyodbc.Error as e:
            error_message = '数据库查询失败，请稍后再试'
            print(f"[数据库错误] {e}")
        return jsonify({'error_message': error_message})
    return render_template('login.html', error_message=error_message)


# 学生页面
@app.route('/student', methods=['GET', 'POST'])
def student():
    if session.get('role') != 'student':    # 如果未登录
        return redirect(url_for('login'))   # 回到登录页面
    
    # 登录成功
    from modules.student import student_action   # 学生数据库操作函数
    results = []
    message = ''
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'select_course':
            result = student_action('select_course',
                student_username=session['user'],
                teacher_id=request.form.get('teacher_id'),
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            message = result['message']
            
        elif action == 'drop_course':
            result = student_action('drop_course',
                student_username=session['user'],
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            message = result['message']
            
        elif action == 'update_profile':
            result = student_action('update_profile',
                student_username=session['user'],
                gender=request.form.get('gender'),
                birth_date=request.form.get('birth_date')
            )
            message = result['message']
            
        elif action == 'get_grades_by_semester':
            result = student_action('get_grades_by_semester',
                student_id=session['user_id'],
                semester=request.form.get('semester')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_grades_by_course':
            result = student_action('get_grades_by_course',
                student_id=session['user_id'],
                course_id=request.form.get('course_id')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_all_grades':
            result = student_action('get_all_grades',
                student_id=session['user_id']
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_courses':
            result = student_action('get_courses',
                student_id=session['user_id']
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_credit':
            result = student_action('get_credit',
                student_id=session['user_id']
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_credit_report':
            result = student_action('get_credit_report',
                student_id=session['user_id']
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_overview':
            result = student_action('get_overview',
                student_id=session['user_id']
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'update_password':
            result = student_action('update_password',
                username=session['user'],
                old_password=request.form.get('old_password'),
                new_password=request.form.get('new_password')
            )
            message = result['message']
            
        elif action == 'get_course_info':
            result = student_action('get_course_info',
                course_id=request.form.get('course_id') or None,
                course_name=request.form.get('course_name') or None,
                teacher_name=request.form.get('teacher_name') or None,
                semester=request.form.get('semester') or None,
                min_credits=int(request.form.get('min_credits')) if request.form.get('min_credits') else None,
                max_credits=int(request.form.get('max_credits')) if request.form.get('max_credits') else None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_course_detail':
            result = student_action('get_course_detail',
                course_id=request.form.get('course_id')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']

    return render_template('student.html', user=session['user'], results=results, message=message)



# 教师页面
@app.route('/teacher', methods=['GET', 'POST'])
def teacher():
    if session.get('role') != 'teacher': # 如果未登录
        return redirect(url_for('login')) # 回到登录页面

    # 登录成功
    from modules.teacher import teacher_action   # 教师数据库操作函数
    results = []
    message = ''
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'insert_grade':
            result = teacher_action('insert_grade',
                teacher_username=session['user'],
                student_id=request.form.get('student_id'),
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester'),
                score=int(request.form.get('score'))
            )
            message = result['message']
            
        elif action == 'delete_grade':
            result = teacher_action('delete_grade',
                teacher_id=session['user_id'],
                student_id=request.form.get('student_id'),
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            message = result['message']
            
        elif action == 'update_profile':
            result = teacher_action('update_profile',
                teacher_username=session['user'],
                department=request.form.get('department'),
                introduction=request.form.get('introduction')
            )
            message = result['message']
            
        elif action == 'get_grades':
            result = teacher_action('get_grades',
                teacher_id=session['user_id'],
                semester=request.form.get('semester') or None,
                course_id=request.form.get('course_id') or None,
                student_id=request.form.get('student_id') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_courses':
            result = teacher_action('get_courses',
                teacher_id=session['user_id'],
                semester=request.form.get('semester') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_students':
            result = teacher_action('get_students',
                teacher_id=session['user_id'],
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_grade_status':
            result = teacher_action('get_grade_status',
                teacher_id=session['user_id'],
                semester=request.form.get('semester') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'update_password':
            result = teacher_action('update_password',
                username=session['user'],
                old_password=request.form.get('old_password'),
                new_password=request.form.get('new_password')
            )
            message = result['message']

    return render_template('teacher.html', user=session['user'], results=results, message=message)



# 管理员页面
@app.route('/admin', methods=['GET', 'POST'])
def admin():
    #print(f"[INFO] 管理员 {session['user']} 登录成功")
    if session.get('role') != 'admin':
        return redirect(url_for('login'))

    # 登录成功
    from modules.admin import admin_action       # 管理员数据库操作函数
    results = []
    message = ''
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'add_user':
            result = admin_action('add_user',
                user_id=request.form.get('user_id'),
                username=request.form.get('username'),
                password=request.form.get('password'),
                role=request.form.get('role'),
                name=request.form.get('name'),
                gender=request.form.get('gender') or None,
                birth_date=request.form.get('birth_date') or None,
                department=request.form.get('department') or None,
                introduction=request.form.get('introduction') or None
            )
            message = result['message']
            
        elif action == 'delete_user':
            result = admin_action('delete_user',
                username=request.form.get('username')
            )
            message = result['message']
            if result['success']:
                results = result.get('data', [])
                
        elif action == 'add_course':
            result = admin_action('add_course',
                course_id=request.form.get('course_id'),
                name=request.form.get('course_name'),
                description=request.form.get('description'),
                credits=int(request.form.get('credits'))
            )
            message = result['message']
            
        elif action == 'delete_course':
            result = admin_action('delete_course',
                course_id=request.form.get('course_id')
            )
            message = result['message']
            if result['success']:
                results = result.get('data', [])
                
        elif action == 'add_tc':
            result = admin_action('add_tc',
                teacher_id=request.form.get('teacher_id'),
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            message = result['message']
            
        elif action == 'delete_tc':
            result = admin_action('delete_tc',
                teacher_id=request.form.get('teacher_id'),
                course_id=request.form.get('course_id'),
                semester=request.form.get('semester')
            )
            message = result['message']
            if result['success']:
                results = result.get('data', [])
                
        elif action == 'get_user_info':
            result = admin_action('get_user_info',
                username=request.form.get('username')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_grades_admin':
            result = admin_action('get_grades_admin',
                username=request.form.get('username')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_system_statistics':
            result = admin_action('get_system_statistics')
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_course_statistics':
            result = admin_action('get_course_statistics',
                semester=request.form.get('semester') or None,
                course_id=request.form.get('course_id') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_semester_statistics':
            result = admin_action('get_semester_statistics',
                semester=request.form.get('semester') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_teacher_statistics':
            result = admin_action('get_teacher_statistics',
                semester=request.form.get('semester') or None,
                teacher_id=request.form.get('teacher_id') or None,
                department=request.form.get('department') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_student_statistics':
            result = admin_action('get_student_statistics',
                student_id=request.form.get('student_id') or None,
                semester=request.form.get('semester') or None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'update_password':
            result = admin_action('update_password',
                username=request.form.get('username'),
                old_password=request.form.get('old_password'),
                new_password=request.form.get('new_password')
            )
            message = result['message']
            
        elif action == 'get_course_info':
            result = admin_action('get_course_info',
                course_id=request.form.get('course_id') or None,
                course_name=request.form.get('course_name') or None,
                teacher_name=request.form.get('teacher_name') or None,
                semester=request.form.get('semester') or None,
                min_credits=int(request.form.get('min_credits')) if request.form.get('min_credits') else None,
                max_credits=int(request.form.get('max_credits')) if request.form.get('max_credits') else None
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
                
        elif action == 'get_course_detail':
            result = admin_action('get_course_detail',
                course_id=request.form.get('course_id')
            )
            if result['success']:
                results = result['data']
            else:
                message = result['message']
    
    return render_template('admin.html', user=session['user'], results=results, message=message)



# 登出按钮: 清除 session, 回到登录页面
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=True)
