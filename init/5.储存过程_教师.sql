USE SchoolDB;
GO

/*
sp_insert_grade
参数：教师用户名、学生ID、课程ID、学期、分数
功能：教师录入或更新学生成绩，使用MERGE语句实现智能插入/更新，包含教师权限验证和学生选课状态检查

sp_delete_grade
参数：教师ID、学生ID、课程ID、学期
功能：删除指定学生的课程成绩，包含完整的权限验证和事务处理，确保只有授课教师才能删除相关成绩

sp_teacher_update_profile
参数：教师用户名、所属部门、个人简介
功能：允许教师更新个人档案信息，包括部门归属和个人介绍

sp_get_grades_teacher
参数：教师ID、学期（可选）、课程ID（可选）、学生ID（可选）
功能：多维度查询教师所教授课程的学生成绩，支持按学期、课程、学生等条件过滤，返回详细成绩信息和统计数据

sp_get_tc_teacher
参数：教师ID、学期（可选）
功能：查询教师的课程安排信息，显示所教授的课程详情和每门课程的选课学生数量

sp_get_sc_teacher
参数：教师ID、课程ID、学期
功能：查询指定课程的选课学生列表，包含学生基本信息和成绩录入状态

sp_get_grade_status_teacher
参数：教师ID、学期（可选）
功能：生成教师成绩录入进度报告，统计每门课程的选课人数、已录入成绩人数、未录入人数和完成率
*/

--教师
--修改成绩，可以插入，也可以更新
CREATE PROCEDURE sp_insert_grade
    @p_teacher_username VARCHAR(50),
    @p_student_id VARCHAR(10),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20),
    @p_score INT
AS
BEGIN
    DECLARE @v_teacher_id VARCHAR(10);
    
    SELECT @v_teacher_id = user_id FROM Users WHERE username = @p_teacher_username AND role = 'teacher';
    IF @v_teacher_id IS NULL
    BEGIN
        THROW 50005, '操作失败：当前用户不是教师或用户不存在。', 1;
    END

    IF NOT EXISTS (
        SELECT * FROM TC
        WHERE teacher_id = @v_teacher_id AND course_id = @p_course_id AND semester = @p_semester
    )
    BEGIN
        THROW 50006, '权限不足：您未在本学期教授此课程。', 1;
    END
    
    IF NOT EXISTS (
        SELECT * FROM SC
        WHERE student_id = @p_student_id AND course_id = @p_course_id AND semester = @p_semester AND teacher_id = @v_teacher_id
    )
    BEGIN
        THROW 50007, '操作失败：该学生未选修您教授的这门课程。', 1;
    END

    MERGE Grades AS target
    USING (SELECT @p_student_id AS student_id, @p_course_id AS course_id, @p_semester AS semester, @p_score AS score) AS source
    ON target.student_id = source.student_id AND target.course_id = source.course_id AND target.semester = source.semester
    WHEN MATCHED THEN
        UPDATE SET score = source.score
    WHEN NOT MATCHED THEN
        INSERT (student_id, course_id, semester, score)
        VALUES (source.student_id, source.course_id, source.semester, source.score);
END;
GO


-- 教师删除某一个学生的成绩
CREATE PROCEDURE sp_delete_grade
    @teacher_id VARCHAR(10),
    @student_id VARCHAR(10),
    @course_id VARCHAR(10),
    @semester VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @grade_exists INT = 0;
    DECLARE @teacher_authority INT = 0;
    DECLARE @error_message NVARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @teacher_authority = COUNT(*)
        FROM TC 
        WHERE teacher_id = @teacher_id 
          AND course_id = @course_id 
          AND semester = @semester;
        
        IF @teacher_authority = 0
        BEGIN
            SET @error_message = '您没有权限删除该课程的成绩，您未教授此课程';
            THROW 50001, @error_message, 1;
        END
        
        SELECT @grade_exists = COUNT(*)
        FROM Grades 
        WHERE student_id = @student_id 
          AND course_id = @course_id 
          AND semester = @semester;
        
        IF @grade_exists = 0
        BEGIN
            SET @error_message = '指定的成绩记录不存在';
            THROW 50002, @error_message, 1;
        END
        
        DELETE FROM Grades 
        WHERE student_id = @student_id 
          AND course_id = @course_id 
          AND semester = @semester;
        
        COMMIT TRANSACTION;
        
        SELECT '成功删除成绩: 学生ID=' + @student_id + 
               ', 课程ID=' + @course_id + 
               ', 学期=' + @semester AS result;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO


-- 存储过程：教师更新自己的个人信息 
CREATE PROCEDURE sp_teacher_update_profile
    @p_teacher_username VARCHAR(50),
    @p_department VARCHAR(50),
    @p_introduction TEXT
AS
BEGIN
    BEGIN TRY
        DECLARE @v_teacher_id VARCHAR(10);
        
        SELECT @v_teacher_id = user_id FROM Users WHERE username = @p_teacher_username AND role = 'teacher';
        IF @v_teacher_id IS NULL
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '操作失败：用户(' + @p_teacher_username + ')不是教师或不存在。';
            THROW 50008, @error_msg1, 1;
        END

        UPDATE Teachers
        SET
            department = @p_department,
            introduction = @p_introduction
        WHERE teacher_id = @v_teacher_id;

        DECLARE @success_msg VARCHAR(200) = '教师(' + @p_teacher_username + ')的个人信息已更新。';
        PRINT @success_msg;
    END TRY
    BEGIN CATCH
        DECLARE @error_msg2 VARCHAR(200) = '更新教师信息失败: ' + ERROR_MESSAGE();
        THROW 50009, @error_msg2, 1;
    END CATCH
END;
GO


-- 以下为查询信息
CREATE PROCEDURE sp_get_grades_teacher
    @TeacherId VARCHAR(10),
    @Semester VARCHAR(20) = NULL,
    @CourseId VARCHAR(10) = NULL,
    @StudentId VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @TeacherId IS NULL OR @TeacherId = ''
    BEGIN
        RAISERROR('教师ID不能为空', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM Teachers WHERE teacher_id = @TeacherId)
    BEGIN
        RAISERROR('教师不存在', 16, 1);
        RETURN;
    END
    
    SELECT 
        g.student_id,
        s.name AS student_name,
        c.course_id,
        c.name AS course_name,
        c.credits,
        g.semester,
        g.score,
        t.name AS teacher_name,
        CASE 
            WHEN g.score >= 90 THEN '优秀'
            WHEN g.score >= 80 THEN '良好'
            WHEN g.score >= 70 THEN '中等'
            WHEN g.score >= 60 THEN '及格'
            WHEN g.score < 60 THEN '不及格'
            ELSE '未录入'
        END AS grade_level,
        CASE 
            WHEN g.score >= 60 THEN '已获得学分'
            WHEN g.score < 60 THEN '未获得学分'
            ELSE '未录入成绩'
        END AS credit_status
    FROM Grades g
    INNER JOIN Students s ON g.student_id = s.student_id
    INNER JOIN Courses c ON g.course_id = c.course_id
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    WHERE sc.teacher_id = @TeacherId
        AND (@Semester IS NULL OR g.semester = @Semester)
        AND (@CourseId IS NULL OR g.course_id = @CourseId)
        AND (@StudentId IS NULL OR g.student_id = @StudentId)
    ORDER BY g.semester DESC, c.course_id, s.name;
    
    -- 返回统计信息
    SELECT 
        COUNT(*) AS total_records,
        COUNT(CASE WHEN g.score >= 60 THEN 1 END) AS passed_count,
        COUNT(CASE WHEN g.score < 60 THEN 1 END) AS failed_count,
        ROUND(AVG(CAST(g.score AS FLOAT)), 2) AS average_score,
        MAX(g.score) AS highest_score,
        MIN(g.score) AS lowest_score
    FROM Grades g
    INNER JOIN SC sc ON g.student_id = sc.student_id 
        AND g.course_id = sc.course_id 
        AND g.semester = sc.semester
    WHERE sc.teacher_id = @TeacherId
        AND (@Semester IS NULL OR g.semester = @Semester)
        AND (@CourseId IS NULL OR g.course_id = @CourseId)
        AND (@StudentId IS NULL OR g.student_id = @StudentId);
END
GO


CREATE PROCEDURE sp_get_tc_teacher
    @TeacherId VARCHAR(10),
    @Semester VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tc.course_id,
        c.name AS course_name,
        CAST(c.description AS NVARCHAR(MAX)) AS description,  -- 转换text类型
        c.credits,
        tc.semester,
        COUNT(sc.student_id) AS enrolled_students
    FROM TC tc
    INNER JOIN Courses c ON tc.course_id = c.course_id
    LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
        AND tc.course_id = sc.course_id 
        AND tc.semester = sc.semester
    WHERE tc.teacher_id = @TeacherId
        AND (@Semester IS NULL OR tc.semester = @Semester)
    GROUP BY tc.course_id, c.name, CAST(c.description AS NVARCHAR(MAX)), c.credits, tc.semester
    ORDER BY tc.semester DESC, tc.course_id;
END
GO


CREATE PROCEDURE sp_get_sc_teacher
    @TeacherId VARCHAR(10),
    @CourseId VARCHAR(10),
    @Semester VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        s.student_id,
        s.name AS student_name,
        s.gender,
        u.username,
        ISNULL(g.score, -1) AS score,
        CASE 
            WHEN g.score IS NULL THEN '未录入'
            WHEN g.score >= 60 THEN '及格'
            ELSE '不及格'
        END AS status
    FROM SC sc
    INNER JOIN Students s ON sc.student_id = s.student_id
    INNER JOIN Users u ON s.student_id = u.user_id
    LEFT JOIN Grades g ON sc.student_id = g.student_id 
        AND sc.course_id = g.course_id 
        AND sc.semester = g.semester
    WHERE sc.teacher_id = @TeacherId
        AND sc.course_id = @CourseId
        AND sc.semester = @Semester
    ORDER BY s.student_id;
END
GO


CREATE PROCEDURE sp_get_grade_status_teacher
    @TeacherId VARCHAR(10),
    @Semester VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.course_id,
        c.name AS course_name,
        sc_count.semester,
        sc_count.enrolled_students,
        ISNULL(g_count.graded_students, 0) AS graded_students,
        (sc_count.enrolled_students - ISNULL(g_count.graded_students, 0)) AS ungraded_students,
        CASE 
            WHEN sc_count.enrolled_students = 0 THEN 0
            ELSE ROUND(CAST(ISNULL(g_count.graded_students, 0) AS FLOAT) / sc_count.enrolled_students * 100, 2)
        END AS completion_rate
    FROM (
        SELECT 
            sc.course_id,
            sc.semester,
            COUNT(sc.student_id) AS enrolled_students
        FROM SC sc
        WHERE sc.teacher_id = @TeacherId
            AND (@Semester IS NULL OR sc.semester = @Semester)
        GROUP BY sc.course_id, sc.semester
    ) sc_count
    LEFT JOIN (
        SELECT 
            g.course_id,
            g.semester,
            COUNT(g.student_id) AS graded_students
        FROM Grades g
        INNER JOIN SC sc ON g.student_id = sc.student_id 
            AND g.course_id = sc.course_id 
            AND g.semester = sc.semester
        WHERE sc.teacher_id = @TeacherId
            AND (@Semester IS NULL OR g.semester = @Semester)
        GROUP BY g.course_id, g.semester
    ) g_count ON sc_count.course_id = g_count.course_id 
        AND sc_count.semester = g_count.semester
    INNER JOIN Courses c ON sc_count.course_id = c.course_id
    ORDER BY sc_count.semester DESC, sc_count.course_id;
END