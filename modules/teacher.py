
if __name__ == '__main__':
    from config import create_connection
else:
    from .config import create_connection



""" 教师用户操作 API
接收来自网页的命令
解析命令并执行相应的操作
返回结果
"""
from modules.config import execute_query

def teacher_action(action_type, **kwargs):
    """
    教师操作处理函数
    """
    try:
        if action_type == 'insert_grade':
            return insert_grade(kwargs['teacher_username'], kwargs['student_id'], 
                              kwargs['course_id'], kwargs['semester'], kwargs['score'])
        elif action_type == 'delete_grade':
            return delete_grade(kwargs['teacher_id'], kwargs['student_id'], 
                              kwargs['course_id'], kwargs['semester'])
        elif action_type == 'update_profile':
            return update_profile(kwargs['teacher_username'], kwargs['department'], 
                                kwargs['introduction'])
        elif action_type == 'get_grades':
            return get_grades(kwargs['teacher_id'], kwargs.get('semester'), 
                            kwargs.get('course_id'), kwargs.get('student_id'))
        elif action_type == 'get_courses':
            return get_courses(kwargs['teacher_id'], kwargs.get('semester'))
        elif action_type == 'get_students':
            return get_students(kwargs['teacher_id'], kwargs['course_id'], kwargs['semester'])
        elif action_type == 'get_grade_status':
            return get_grade_status(kwargs['teacher_id'], kwargs.get('semester'))
        elif action_type == 'update_password':
            return update_password(kwargs['username'], kwargs['old_password'], 
                                 kwargs['new_password'])
        elif action_type == 'get_course_info':
            return get_course_info(kwargs.get('course_id'), kwargs.get('course_name'),
                                 kwargs.get('teacher_name'), kwargs.get('semester'),
                                 kwargs.get('min_credits'), kwargs.get('max_credits'))
        else:
            return {'success': False, 'message': '未知操作类型'}
    except Exception as e:
        return {'success': False, 'message': str(e)}

def insert_grade(teacher_username, student_id, course_id, semester, score):
    """录入或更新学生成绩"""
    try:
        execute_query(
            "EXEC sp_insert_grade @p_teacher_username=?, @p_student_id=?, @p_course_id=?, @p_semester=?, @p_score=?",
            (teacher_username, student_id, course_id, semester, score)
        )
        return {'success': True, 'message': '成绩录入成功'}
    except Exception as e:
        return {'success': False, 'message': f'成绩录入失败: {str(e)}'}

def delete_grade(teacher_id, student_id, course_id, semester):
    """删除学生成绩"""
    try:
        result = execute_query(
            "EXEC sp_delete_grade @teacher_id=?, @student_id=?, @course_id=?, @semester=?",
            (teacher_id, student_id, course_id, semester)
        )
        return {'success': True, 'message': '成绩删除成功'}
    except Exception as e:
        return {'success': False, 'message': f'成绩删除失败: {str(e)}'}

def update_profile(teacher_username, department, introduction):
    """更新教师个人信息"""
    try:
        execute_query(
            "EXEC sp_teacher_update_profile @p_teacher_username=?, @p_department=?, @p_introduction=?",
            (teacher_username, department, introduction)
        )
        return {'success': True, 'message': '个人信息更新成功'}
    except Exception as e:
        return {'success': False, 'message': f'个人信息更新失败: {str(e)}'}

def get_grades(teacher_id, semester=None, course_id=None, student_id=None):
    """查询成绩信息"""
    try:
        grades = execute_query(
            "EXEC sp_get_grades_teacher @TeacherId=?, @Semester=?, @CourseId=?, @StudentId=?",
            (teacher_id, semester, course_id, student_id)
        )
        return {'success': True, 'data': grades}
    except Exception as e:
        return {'success': False, 'message': f'查询成绩失败: {str(e)}'}

def get_courses(teacher_id, semester=None):
    """查询教师课程安排"""
    try:
        courses = execute_query(
            "EXEC sp_get_tc_teacher @TeacherId=?, @Semester=?",
            (teacher_id, semester)
        )
        return {'success': True, 'data': courses}
    except Exception as e:
        return {'success': False, 'message': f'查询课程失败: {str(e)}'}

def get_students(teacher_id, course_id, semester):
    """查询选课学生列表"""
    try:
        students = execute_query(
            "EXEC sp_get_sc_teacher @TeacherId=?, @CourseId=?, @Semester=?",
            (teacher_id, course_id, semester)
        )
        return {'success': True, 'data': students}
    except Exception as e:
        return {'success': False, 'message': f'查询学生失败: {str(e)}'}

def get_grade_status(teacher_id, semester=None):
    """查询成绩录入状态"""
    try:
        status = execute_query(
            "EXEC sp_get_grade_status_teacher @TeacherId=?, @Semester=?",
            (teacher_id, semester)
        )
        return {'success': True, 'data': status}
    except Exception as e:
        return {'success': False, 'message': f'查询成绩状态失败: {str(e)}'}

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
