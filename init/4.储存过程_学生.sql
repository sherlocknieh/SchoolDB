USE SchoolDB;
GO
/*
sp_student_select_course
参数：学生用户名、教师ID、课程ID、学期
功能：验证学生身份后，为学生选择指定教师的课程，包含重复选课检查和课程安排验证

sp_student_drop_course
参数：学生用户名、课程ID、学期
功能：学生退选指定学期的课程，验证选课记录存在性并执行删除操作

sp_student_update_profile
参数：学生用户名、性别、出生日期
功能：允许学生更新个人基本信息，包括性别和出生日期

sp_get_grades_by_semester
参数：学生ID、学期
功能：查询指定学生在特定学期的所有课程成绩，包含课程信息和教师信息

sp_get_grades_by_course
参数：学生ID、课程ID
功能：查询指定学生某门课程的历史成绩记录，按学期倒序排列

sp_get_all_grades
参数：学生ID
功能：查询学生所有课程成绩，包含及格状态判断

sp_get_courses
参数：学生ID
功能：显示学生所有修读课程的详细信息和学分获得状态

sp_get_credit
参数：学生ID
功能：统计学生的学分情况，包括总学分、已获得学分、平均绩点等核心指标

sp_get_credit_report
参数：学生ID
功能：生成详细的学分报告，包含分数段分析和各等级统计信息

sp_get_overview
参数：学生ID
功能：提供学生完整概览，包括个人信息、学分统计和最近课程记录
*/

--学生选课
CREATE PROCEDURE sp_student_select_course
    @p_student_username VARCHAR(50),
    @p_teacher_id VARCHAR(10),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        DECLARE @v_student_id VARCHAR(10);
        
        SELECT @v_student_id = user_id FROM Users WHERE username = @p_student_username AND role = 'student';
        IF @v_student_id IS NULL
        BEGIN
            THROW 50010, '操作失败：当前用户不是学生或用户不存在。', 1;
        END

        IF NOT EXISTS (
            SELECT * FROM TC
            WHERE teacher_id = @p_teacher_id AND course_id = @p_course_id AND semester = @p_semester
        )
        BEGIN
            THROW 50011, '选课失败：该课程安排不存在。', 1;
        END

        INSERT INTO SC (student_id, teacher_id, course_id, semester)
        VALUES (@v_student_id, @p_teacher_id, @p_course_id, @p_semester);
        
        PRINT '选课成功！';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627 -- 主键冲突
        BEGIN
            THROW 50012, '选课失败：您在本学期已选修该课程。', 1;
        END
        ELSE
        BEGIN
            DECLARE @error_msg VARCHAR(200) = '选课失败: ' + ERROR_MESSAGE();
            THROW 50013, @error_msg, 1;
        END
    END CATCH
END;
GO


-- 存储过程：学生更新自己的个人信息
CREATE PROCEDURE sp_student_update_profile
    @p_student_username VARCHAR(50),
    @p_gender VARCHAR(10),
    @p_birth_date DATE
AS
BEGIN
    BEGIN TRY
        DECLARE @v_student_id VARCHAR(10);
        
        SELECT @v_student_id = user_id FROM Users WHERE username = @p_student_username AND role = 'student';
        IF @v_student_id IS NULL
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '操作失败：用户(' + @p_student_username + ')不是学生或不存在。';
            THROW 50014, @error_msg1, 1;
        END

        UPDATE Students
        SET
            gender = @p_gender,
            birth_date = @p_birth_date
        WHERE student_id = @v_student_id;

        DECLARE @success_msg VARCHAR(200) = '学生(' + @p_student_username + ')的个人信息已更新。';
        PRINT @success_msg;
    END TRY
    BEGIN CATCH
        DECLARE @error_msg2 VARCHAR(200) = '更新学生信息失败: ' + ERROR_MESSAGE();
        THROW 50015, @error_msg2, 1;
    END CATCH
END;
GO


-- 存储过程：学生退选课程
CREATE PROCEDURE sp_student_drop_course
    @p_student_username VARCHAR(50),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20)
AS 
BEGIN
    BEGIN TRY
        DECLARE @v_student_id VARCHAR(10);
        DECLARE @rowcount INT;
        
        SELECT @v_student_id = user_id FROM Users WHERE username = @p_student_username AND role = 'student';
        IF @v_student_id IS NULL
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '操作失败：用户(' + @p_student_username + ')不是学生或不存在。';
            THROW 50016, @error_msg1, 1;
        END

        DELETE FROM SC
        WHERE student_id = @v_student_id
          AND course_id = @p_course_id
          AND semester = @p_semester;

        SET @rowcount = @@ROWCOUNT;
        IF @rowcount = 0
        BEGIN
            DECLARE @error_msg2 VARCHAR(200) = '退课失败：您并未在学期(' + @p_semester + ')选修课程(' + @p_course_id + ')。';
            THROW 50017, @error_msg2, 1;
        END

        DECLARE @success_msg VARCHAR(200) = '学生(' + @p_student_username + ')已成功退选课程(' + @p_course_id + ')。';
        PRINT @success_msg;
    END TRY
    BEGIN CATCH
        DECLARE @error_msg VARCHAR(200) = '退课失败: ' + ERROR_MESSAGE();
        THROW 50018, @error_msg, 1;
    END CATCH
END;
GO


-- 以下为三个查询成绩的方式
CREATE PROCEDURE sp_get_grades_by_semester
    @StudentId VARCHAR(10),
    @Semester VARCHAR(20)
AS
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.credits,
        t.name AS teacher_name,
        g.score,
        g.semester
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    WHERE g.student_id = @StudentId AND g.semester = @Semester
    ORDER BY c.course_id;
END
GO


CREATE PROCEDURE sp_get_grades_by_course
    @StudentId VARCHAR(10),
    @CourseId VARCHAR(10)
AS
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.credits,
        t.name AS teacher_name,
        g.score,
        g.semester
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    WHERE g.student_id = @StudentId AND g.course_id = @CourseId
    ORDER BY g.semester DESC;
END
GO


CREATE PROCEDURE sp_get_all_grades
    @StudentId VARCHAR(10)
AS
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.credits,
        t.name AS teacher_name,
        g.score,
        g.semester,
        CASE 
            WHEN g.score >= 60 THEN '及格'
            ELSE '不及格'
        END AS status
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    WHERE g.student_id = @StudentId
    ORDER BY g.semester DESC, c.course_id;
END
GO


-- 以下为统计功能的实现
CREATE PROCEDURE sp_get_courses
    @StudentId VARCHAR(10)
AS
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.credits,
        t.name AS teacher_name,
        g.score,
        g.semester,
        CASE 
            WHEN g.score >= 60 THEN '已获得学分'
            ELSE '未获得学分'
        END AS credit_status
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    WHERE g.student_id = @StudentId
    ORDER BY g.semester DESC, c.course_id;
END
GO


CREATE PROCEDURE sp_get_credit
    @StudentId VARCHAR(10)
AS
BEGIN
    SELECT 
        COUNT(*) AS total_courses,
        SUM(CASE WHEN g.score >= 60 THEN c.credits ELSE 0 END) AS earned_credits,
        SUM(c.credits) AS total_attempted_credits,
        ROUND(AVG(CAST(g.score AS FLOAT)), 2) AS overall_gpa,
        COUNT(CASE WHEN g.score >= 60 THEN 1 END) AS passed_courses,
        COUNT(CASE WHEN g.score < 60 THEN 1 END) AS failed_courses
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    WHERE g.student_id = @StudentId;
END
GO


CREATE PROCEDURE sp_get_credit_report
    @StudentId VARCHAR(10)
AS
BEGIN
    SELECT 
        '总体统计' AS category,
        COUNT(DISTINCT g.course_id) AS total_courses,
        SUM(c.credits) AS total_attempted_credits,
        SUM(CASE WHEN g.score >= 60 THEN c.credits ELSE 0 END) AS earned_credits,
        SUM(CASE WHEN g.score < 60 THEN c.credits ELSE 0 END) AS failed_credits,
        ROUND(AVG(CAST(g.score AS FLOAT)), 2) AS overall_gpa,
        COUNT(CASE WHEN g.score >= 90 THEN 1 END) AS excellent_count,
        COUNT(CASE WHEN g.score >= 80 AND g.score < 90 THEN 1 END) AS good_count,
        COUNT(CASE WHEN g.score >= 70 AND g.score < 80 THEN 1 END) AS fair_count,
        COUNT(CASE WHEN g.score >= 60 AND g.score < 70 THEN 1 END) AS pass_count,
        COUNT(CASE WHEN g.score < 60 THEN 1 END) AS fail_count
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    WHERE g.student_id = @StudentId;
    
    SELECT 
        CASE 
            WHEN g.score >= 90 THEN '优秀(90-100)'
            WHEN g.score >= 80 THEN '良好(80-89)'
            WHEN g.score >= 70 THEN '中等(70-79)'
            WHEN g.score >= 60 THEN '及格(60-69)'
            ELSE '不及格(0-59)'
        END AS grade_level,
        COUNT(*) AS course_count,
        SUM(c.credits) AS credits_in_level,
        ROUND(AVG(CAST(g.score AS FLOAT)), 2) AS avg_score_in_level
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    WHERE g.student_id = @StudentId
    GROUP BY 
        CASE 
            WHEN g.score >= 90 THEN '优秀(90-100)'
            WHEN g.score >= 80 THEN '良好(80-89)'
            WHEN g.score >= 70 THEN '中等(70-79)'
            WHEN g.score >= 60 THEN '及格(60-69)'
            ELSE '不及格(0-59)'
        END
    ORDER BY MIN(g.score) DESC;
END
GO


CREATE PROCEDURE sp_get_overview
    @StudentId VARCHAR(10)
AS
BEGIN
    SELECT 
        s.student_id,
        s.name AS student_name,
        s.gender,
        s.birth_date,
        u.username
    FROM Students s
    INNER JOIN Users u ON s.student_id = u.user_id
    WHERE s.student_id = @StudentId;
    
    SELECT 
        COUNT(*) AS total_courses,
        SUM(c.credits) AS total_attempted_credits,
        SUM(CASE WHEN g.score >= 60 THEN c.credits ELSE 0 END) AS earned_credits,
        ROUND(AVG(CAST(g.score AS FLOAT)), 2) AS overall_gpa
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    WHERE g.student_id = @StudentId;
    
    SELECT TOP 10
        c.name AS course_name,
        g.score,
        c.credits,
        g.semester
    FROM Grades g
    INNER JOIN Courses c ON g.course_id = c.course_id
    WHERE g.student_id = @StudentId
    ORDER BY g.semester DESC, c.course_id;
END