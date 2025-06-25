from modules.tools import execute_query

def admin_action(action=None, **kwargs):
    """管理员操作函数"""
    try:
        if action == 'add_user':
            return add_user(kwargs['user_id'], kwargs['username'], kwargs['password'], 
                          kwargs['role'], kwargs['name'], kwargs.get('gender'), 
                          kwargs.get('birth_date'), kwargs.get('department'), 
                          kwargs.get('introduction'))
        elif action == 'delete_user':
            return delete_user(kwargs['username'])
        elif action == 'add_course':
            return add_course(kwargs['course_id'], kwargs['name'], 
                            kwargs['description'], kwargs['credits'])
        elif action == 'delete_course':
            return delete_course(kwargs['course_id'])
        elif action == 'add_tc':
            return add_tc(kwargs['teacher_id'], kwargs['course_id'], kwargs['semester'])
        elif action == 'delete_tc':
            return delete_tc(kwargs['teacher_id'], kwargs['course_id'], kwargs['semester'])
        elif action == 'get_user_info':
            return get_user_info(kwargs['username'])
        elif action == 'get_grades_admin':
            return get_grades_admin(kwargs['username'])
        elif action == 'get_system_statistics':
            return get_system_statistics()
        elif action == 'get_course_statistics':
            return get_course_statistics(kwargs.get('semester'), kwargs.get('course_id'))
        elif action == 'get_semester_statistics':
            return get_semester_statistics(kwargs.get('semester'))
        elif action == 'get_teacher_statistics':
            return get_teacher_statistics(kwargs.get('semester'), kwargs.get('teacher_id'), 
                                        kwargs.get('department'))
        elif action == 'get_student_statistics':
            return get_student_statistics(kwargs.get('student_id'), kwargs.get('semester'))
        elif action == 'update_password':
            return update_password(kwargs['username'], kwargs['old_password'], 
                                 kwargs['new_password'])
        elif action == 'get_course_info':
            return get_course_info(kwargs.get('course_id'), kwargs.get('course_name'),
                                 kwargs.get('teacher_name'), kwargs.get('semester'),
                                 kwargs.get('min_credits'), kwargs.get('max_credits'))
        elif action == 'get_course_detail':
            return get_course_detail(kwargs['course_id'])
        else:
            return {'success': False, 'message': '未知操作'}
    except Exception as e:
        return {'success': False, 'message': f'操作失败: {str(e)}'}

def add_user(user_id, username, password, role, name, gender=None, birth_date=None, department=None, introduction=None):
    """添加用户"""
    try:
        execute_query(
            "EXEC sp_add_user @p_id=?, @p_username=?, @p_password=?, @p_role=?, @p_name=?, @p_gender=?, @p_birth_date=?, @p_department=?, @p_introduction=?",
            (user_id, username, password, role, name, gender, birth_date, department, introduction)
        )
        return {'success': True, 'message': f'用户添加成功'}
    except Exception as e:
        return {'success': False, 'message': f'添加用户失败: {str(e)}'}

def delete_user(username):
    """删除用户"""
    try:
        result = execute_query("EXEC sp_delete_user @p_username=?", (username,))
        return {'success': True, 'message': '用户删除成功', 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'删除用户失败: {str(e)}'}

def add_course(course_id, name, description, credits):
    """添加课程"""
    try:
        execute_query(
            "EXEC sp_add_course @p_course_id=?, @p_name=?, @p_description=?, @p_credits=?",
            (course_id, name, description, credits)
        )
        return {'success': True, 'message': '课程添加成功'}
    except Exception as e:
        return {'success': False, 'message': f'添加课程失败: {str(e)}'}

def delete_course(course_id):
    """删除课程"""
    try:
        result = execute_query("EXEC sp_delete_course @course_id=?", (course_id,))
        return {'success': True, 'message': '课程删除成功', 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'删除课程失败: {str(e)}'}

def add_tc(teacher_id, course_id, semester):
    """添加教学任务"""
    try:
        execute_query(
            "EXEC sp_add_tc @p_teacher_id=?, @p_course_id=?, @p_semester=?",
            (teacher_id, course_id, semester)
        )
        return {'success': True, 'message': '教学任务添加成功'}
    except Exception as e:
        return {'success': False, 'message': f'添加教学任务失败: {str(e)}'}

def delete_tc(teacher_id, course_id, semester):
    """删除教学任务"""
    try:
        result = execute_query(
            "EXEC sp_delete_tc @teacher_id=?, @course_id=?, @semester=?",
            (teacher_id, course_id, semester)
        )
        return {'success': True, 'message': '教学任务删除成功', 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'删除教学任务失败: {str(e)}'}

def get_user_info(username):
    """获取用户信息"""
    try:
        result = execute_query("EXEC sp_get_user_info @username=?", (username,))
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取用户信息失败: {str(e)}'}

def get_grades_admin(username):
    """管理员获取学生成绩"""
    try:
        result = execute_query("EXEC sp_get_grades_admin @username=?", (username,))
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取成绩失败: {str(e)}'}

def get_system_statistics():
    """获取系统统计"""
    try:
        result = execute_query("EXEC sp_admin_get_system_statistics")
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取系统统计失败: {str(e)}'}

def get_course_statistics(semester=None, course_id=None):
    """获取课程统计"""
    try:
        result = execute_query(
            "EXEC sp_admin_get_course_statistics @semester=?, @course_id=?",
            (semester, course_id)
        )
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取课程统计失败: {str(e)}'}

def get_semester_statistics(semester=None):
    """获取学期统计"""
    try:
        result = execute_query("EXEC sp_admin_get_semester_statistics @semester=?", (semester,))
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取学期统计失败: {str(e)}'}

def get_teacher_statistics(semester=None, teacher_id=None, department=None):
    """获取教师统计"""
    try:
        result = execute_query(
            "EXEC sp_admin_get_teacher_statistics @semester=?, @teacher_id=?, @department=?",
            (semester, teacher_id, department)
        )
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取教师统计失败: {str(e)}'}

def get_student_statistics(student_id=None, semester=None):
    """获取学生统计"""
    try:
        result = execute_query(
            "EXEC sp_admin_get_student_stastic @student_id=?, @semester=?",
            (student_id, semester)
        )
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取学生统计失败: {str(e)}'}

def update_password(username, old_password, new_password):
    """修改密码"""
    try:
        execute_query(
            "EXEC sp_update_password @p_username=?, @p_old_password=?, @p_new_password=?",
            (username, old_password, new_password)
        )
        return {'success': True, 'message': '密码修改成功'}
    except Exception as e:
        return {'success': False, 'message': f'修改密码失败: {str(e)}'}

def get_course_info(course_id=None, course_name=None, teacher_name=None, semester=None, min_credits=None, max_credits=None):
    """获取课程信息"""
    try:
        result = execute_query(
            "EXEC sp_get_course_info_public @course_id=?, @course_name=?, @teacher_name=?, @semester=?, @min_credits=?, @max_credits=?",
            (course_id, course_name, teacher_name, semester, min_credits, max_credits)
        )
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取课程信息失败: {str(e)}'}

def get_course_detail(course_id):
    """获取课程详情"""
    try:
        result = execute_query("EXEC sp_get_course_detail_public @course_id=?", (course_id,))
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'message': f'获取课程详情失败: {str(e)}'}
