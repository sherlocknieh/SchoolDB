from modules.config import execute_query

def student_action(action_type, **kwargs):
    """
    学生操作处理函数
    """
    try:
        if action_type == 'select_course':
            return select_course(kwargs['student_username'], kwargs['teacher_id'], 
                                kwargs['course_id'], kwargs['semester'])
        elif action_type == 'drop_course':
            return drop_course(kwargs['student_username'], kwargs['course_id'], 
                             kwargs['semester'])
        elif action_type == 'update_profile':
            return update_profile(kwargs['student_username'], kwargs['gender'], 
                                kwargs['birth_date'])
        elif action_type == 'get_grades_by_semester':
            return get_grades_by_semester(kwargs['student_id'], kwargs['semester'])
        elif action_type == 'get_grades_by_course':
            return get_grades_by_course(kwargs['student_id'], kwargs['course_id'])
        elif action_type == 'get_all_grades':
            return get_all_grades(kwargs['student_id'])
        elif action_type == 'get_courses':
            return get_courses(kwargs['student_id'])
        elif action_type == 'get_credit':
            return get_credit(kwargs['student_id'])
        elif action_type == 'get_credit_report':
            return get_credit_report(kwargs['student_id'])
        elif action_type == 'get_overview':
            return get_overview(kwargs['student_id'])
        elif action_type == 'update_password':
            return update_password(kwargs['username'], kwargs['old_password'], 
                                 kwargs['new_password'])
        elif action_type == 'get_course_info':
            return get_course_info(kwargs.get('course_id'), kwargs.get('course_name'),
                                 kwargs.get('teacher_name'), kwargs.get('semester'),
                                 kwargs.get('min_credits'), kwargs.get('max_credits'))
        elif action_type == 'get_course_detail':
            return get_course_detail(kwargs['course_id'])
        else:
            return {'success': False, 'message': '未知操作类型'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def select_course(student_username, teacher_id, course_id, semester):
    """学生选课"""
    try:
        execute_query(
            "EXEC sp_student_select_course @p_student_username=?, @p_teacher_id=?, @p_course_id=?, @p_semester=?",
            (student_username, teacher_id, course_id, semester)
        )
        return {'success': True, 'message': '选课成功'}
    except Exception as e:
        return {'success': False, 'message': f'选课失败: {str(e)}'}

def drop_course(student_username, course_id, semester):
    """学生退课"""
    try:
        execute_query(
            "EXEC sp_student_drop_course @p_student_username=?, @p_course_id=?, @p_semester=?",
            (student_username, course_id, semester)
        )
        return {'success': True, 'message': '退课成功'}
    except Exception as e:
        return {'success': False, 'message': f'退课失败: {str(e)}'}

def update_profile(student_username, gender, birth_date):
    """更新学生个人信息"""
    try:
        execute_query(
            "EXEC sp_student_update_profile @p_student_username=?, @p_gender=?, @p_birth_date=?",
            (student_username, gender, birth_date)
        )
        return {'success': True, 'message': '个人信息更新成功'}
    except Exception as e:
        return {'success': False, 'message': f'个人信息更新失败: {str(e)}'}

def get_grades_by_semester(student_id, semester):
    """按学期查询成绩"""
    try:
        grades = execute_query(
            "EXEC sp_get_grades_by_semester @StudentId=?, @Semester=?",
            (student_id, semester)
        )
        return {'success': True, 'data': grades}
    except Exception as e:
        return {'success': False, 'message': f'查询成绩失败: {str(e)}'}

def get_grades_by_course(student_id, course_id):
    """按课程查询成绩"""
    try:
        grades = execute_query(
            "EXEC sp_get_grades_by_course @StudentId=?, @CourseId=?",
            (student_id, course_id)
        )
        return {'success': True, 'data': grades}
    except Exception as e:
        return {'success': False, 'message': f'查询成绩失败: {str(e)}'}

def get_all_grades(student_id):
    """查询所有成绩"""
    try:
        grades = execute_query(
            "EXEC sp_get_all_grades @StudentId=?",
            (student_id,)
        )
        return {'success': True, 'data': grades}
    except Exception as e:
        return {'success': False, 'message': f'查询成绩失败: {str(e)}'}

def get_courses(student_id):
    """查询学生课程"""
    try:
        courses = execute_query(
            "EXEC sp_get_courses @StudentId=?",
            (student_id,)
        )
        return {'success': True, 'data': courses}
    except Exception as e:
        return {'success': False, 'message': f'查询课程失败: {str(e)}'}

def get_credit(student_id):
    """查询学分统计"""
    try:
        credit = execute_query(
            "EXEC sp_get_credit @StudentId=?",
            (student_id,)
        )
        return {'success': True, 'data': credit}
    except Exception as e:
        return {'success': False, 'message': f'查询学分失败: {str(e)}'}

def get_credit_report(student_id):
    """查询学分报告"""
    try:
        report = execute_query(
            "EXEC sp_get_credit_report @StudentId=?",
            (student_id,)
        )
        return {'success': True, 'data': report}
    except Exception as e:
        return {'success': False, 'message': f'查询学分报告失败: {str(e)}'}

def get_overview(student_id):
    """查询学生概览"""
    try:
        overview = execute_query(
            "EXEC sp_get_overview @StudentId=?",
            (student_id,)
        )
        return {'success': True, 'data': overview}
    except Exception as e:
        return {'success': False, 'message': f'查询概览失败: {str(e)}'}

def update_password(username, old_password, new_password):
    """修改密码"""
    try:
        execute_query(
            "EXEC sp_update_password @p_username=?, @p_old_password=?, @p_new_password=?",
            (username, old_password, new_password)
        )
        return {'success': True, 'message': '密码修改成功'}
    except Exception as e:
        return {'success': False, 'message': f'密码修改失败: {str(e)}'}

def get_course_info(course_id=None, course_name=None, teacher_name=None, 
                   semester=None, min_credits=None, max_credits=None):
    """查询课程信息"""
    try:
        courses = execute_query(
            "EXEC sp_get_course_info_public @course_id=?, @course_name=?, @teacher_name=?, @semester=?, @min_credits=?, @max_credits=?",
            (course_id, course_name, teacher_name, semester, min_credits, max_credits)
        )
        return {'success': True, 'data': courses}
    except Exception as e:
        return {'success': False, 'message': f'查询课程信息失败: {str(e)}'}

def get_course_detail(course_id):
    """查询课程详情"""
    try:
        detail = execute_query(
            "EXEC sp_get_course_detail_public @course_id=?",
            (course_id,)
        )
        return {'success': True, 'data': detail}
    except Exception as e:
        return {'success': False, 'message': f'查询课程详情失败: {str(e)}'}
