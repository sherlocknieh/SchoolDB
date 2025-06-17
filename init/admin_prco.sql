USE SchoolDB;
GO

--以下是存储过程
--为图方便和安全性，一切插入过程应该由存储过程来实现

/*
需要对应参数
sp_add_user - 添加用户
sp_delete_user - 删除用户
sp_add_course - 添加课程
sp_delete_course - 删除课程
sp_add_tc - 添加教学任务
sp_delete_tc - 删除教学任务
sp_get_user_info - 获取用户信息
sp_get_grades_admin - 管理员获取学生成绩

可以不使用参数
sp_admin_get_system_statistics - 系统统计
sp_admin_get_course_statistics - 课程统计
sp_admin_get_semester_statistics - 学期统计
sp_admin_get_teacher_statistics - 教师统计
sp_admin_get_student_stastic - 学生统计
*/

--管理员
--插入用户
CREATE PROCEDURE sp_add_user
    @p_id VARCHAR(10),
    @p_username VARCHAR(50),
    @p_password VARCHAR(100),
    @p_role VARCHAR(10),
    @p_name VARCHAR(50),
    @p_gender VARCHAR(10) = NULL,
    @p_birth_date DATE = NULL,
    @p_department VARCHAR(50) = NULL,
    @p_introduction TEXT = NULL
AS
BEGIN
    INSERT INTO Users (user_id, username, password, role)
    VALUES (@p_id, @p_username, @p_password, @p_role);

    IF @p_role = 'student' 
    BEGIN
        INSERT INTO Students (student_id, name, gender, birth_date)
        VALUES (@p_id, @p_name, @p_gender, @p_birth_date);
    END
    ELSE IF @p_role = 'teacher'
    BEGIN
        INSERT INTO Teachers (teacher_id, name, department, introduction)
        VALUES (@p_id, @p_name, @p_department, @p_introduction);
    END
    ELSE
    BEGIN
        PRINT 'Admin user created, no entry in Students/Teachers table.';
    END
END;

GO
-- 管理员删除用户，由于在表中实现了ON DELETE CASCADE，可以直接删除
CREATE PROCEDURE sp_delete_user
    @p_username VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_user_id VARCHAR(10);
    DECLARE @v_role VARCHAR(10);
    DECLARE @error_message NVARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @v_user_id = user_id, @v_role = role
        FROM Users 
        WHERE username = @p_username;
        
        IF @v_user_id IS NULL
        BEGIN
            SET @error_message = '用户不存在';
            THROW 50001, @error_message, 1;
        END
        
        IF @v_role = 'admin'
        BEGIN
            SET @error_message = '不能删除管理员账户';
            THROW 50002, @error_message, 1;
        END
        
        DELETE FROM Users WHERE user_id = @v_user_id;
        
        COMMIT TRANSACTION;
        
        SELECT '用户 ' + @p_username + ' 及其所有相关信息已成功删除' AS result;
        
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

-- 如果课程ID已存在，则更新信息；否则，插入新课程。
CREATE PROCEDURE sp_add_course
    @p_course_id VARCHAR(10),
    @p_name VARCHAR(100),
    @p_description TEXT,
    @p_credits INT
AS 
BEGIN
    MERGE Courses AS target
    USING (SELECT @p_course_id AS course_id, @p_name AS name, @p_description AS description, @p_credits AS credits) AS source
    ON target.course_id = source.course_id
    WHEN MATCHED THEN
        UPDATE SET 
            name = source.name,
            description = source.description,
            credits = source.credits
    WHEN NOT MATCHED THEN
        INSERT (course_id, name, description, credits)
        VALUES (source.course_id, source.name, source.description, source.credits);

    DECLARE @msg VARCHAR(200) = '课程信息已成功添加或更新 (ID: ' + @p_course_id + ')';
    PRINT @msg;
END;

GO
--管理员删除某一个课程
CREATE PROCEDURE sp_delete_course
    @course_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @course_exists INT = 0;
    DECLARE @teaching_count INT = 0;
    DECLARE @student_count INT = 0;
    DECLARE @error_message NVARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @course_exists = COUNT(*)
        FROM Courses 
        WHERE course_id = @course_id;
        
        IF @course_exists = 0
        BEGIN
            SET @error_message = '指定的课程不存在';
            THROW 50001, @error_message, 1;
        END

        SELECT @teaching_count = COUNT(*)
        FROM TC 
        WHERE course_id = @course_id;
        
        SELECT @student_count = COUNT(*)
        FROM SC 
        WHERE course_id = @course_id;
        
        IF @teaching_count > 0 OR @student_count > 0
        BEGIN
            PRINT '警告: 该课程有 ' + CAST(@teaching_count AS VARCHAR(10)) + ' 个教学任务和 ' + 
                  CAST(@student_count AS VARCHAR(10)) + ' 个选课记录，删除将影响相关数据';
        END
        
        DELETE FROM Courses WHERE course_id = @course_id;
        
        COMMIT TRANSACTION;
        
        SELECT '课程已成功删除: 课程ID=' + @course_id + 
               CASE WHEN @teaching_count > 0 OR @student_count > 0 
                    THEN ', 同时删除了' + CAST(@teaching_count AS VARCHAR(10)) + '个教学任务和' + 
                         CAST(@student_count AS VARCHAR(10)) + '个选课记录'
                    ELSE '' 
               END AS result;
        
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
-- 存储过程：管理员安排教学任务
CREATE PROCEDURE sp_add_tc
    @p_teacher_id VARCHAR(10),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT * FROM Teachers WHERE teacher_id = @p_teacher_id)
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '安排失败：教师ID(' + @p_teacher_id + ')不存在。';
            THROW 50001, @error_msg1, 1;
        END

        IF NOT EXISTS (SELECT * FROM Courses WHERE course_id = @p_course_id)
        BEGIN
            DECLARE @error_msg2 VARCHAR(200) = '安排失败：课程ID(' + @p_course_id + ')不存在。';
            THROW 50002, @error_msg2, 1;
        END

        INSERT INTO TC (teacher_id, course_id, semester)
        VALUES (@p_teacher_id, @p_course_id, @p_semester);

        DECLARE @success_msg VARCHAR(200) = '已成功为教师(' + @p_teacher_id + ')在学期(' + @p_semester + ')安排课程(' + @p_course_id + ')。';
        PRINT @success_msg;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627 -- 主键冲突
        BEGIN
            THROW 50003, '安排失败：该教学安排已存在。', 1;
        END
        ELSE
        BEGIN
            DECLARE @error_msg3 VARCHAR(200) = '安排教学任务失败: ' + ERROR_MESSAGE();
            THROW 50004, @error_msg3, 1;
        END
    END CATCH
END;

GO

-- 存储过程：管理员删除教学任务，注意如果有学生选课，会一并删除
CREATE PROCEDURE sp_delete_tc
    @teacher_id VARCHAR(10),
    @course_id VARCHAR(10),
    @semester VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @task_count INT = 0;
    DECLARE @student_count INT = 0;
    DECLARE @error_message NVARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SELECT @task_count = COUNT(*)
        FROM TC 
        WHERE teacher_id = @teacher_id 
          AND course_id = @course_id 
          AND semester = @semester;

        IF @task_count = 0
        BEGIN
            SET @error_message = '指定的教学任务不存在';
            THROW 50001, @error_message, 1;
        END
        
        SELECT @student_count = COUNT(*)
        FROM SC 
        WHERE teacher_id = @teacher_id 
          AND course_id = @course_id 
          AND semester = @semester;
        
        IF @student_count > 0
        BEGIN
            PRINT '警告: 该教学任务有 ' + CAST(@student_count AS VARCHAR(10)) + ' 名学生选课，删除将影响学生记录';
        END
        
        DELETE FROM TC 
        WHERE teacher_id = @teacher_id 
          AND course_id = @course_id 
          AND semester = @semester;
        
        COMMIT TRANSACTION;
        SELECT '教学任务已成功删除: 教师ID=' + @teacher_id + 
               ', 课程ID=' + @course_id + 
               ', 学期=' + @semester +
               CASE WHEN @student_count > 0 
                    THEN ', 同时删除了' + CAST(@student_count AS VARCHAR(10)) + '条相关选课记录'
                    ELSE '' 
               END AS result;
        
    END TRY
    BEGIN CATCH
        -- 回滚事务
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- 重新抛出异常
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

GO
--查询功能
CREATE PROCEDURE sp_get_user_info
    @username VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @role VARCHAR(10);
    DECLARE @user_id VARCHAR(10);
    
    SELECT @role = role, @user_id = user_id 
    FROM Users 
    WHERE username = @username;
    
    IF @user_id IS NULL
    BEGIN
        PRINT '用户不存在';
        RETURN;
    END
    
    SELECT 
        user_id AS '用户ID',
        username AS '用户名',
        role AS '角色'
    FROM Users 
    WHERE username = @username;
    
    IF @role = 'student'
    BEGIN
        PRINT '=== 学生详细信息 ===';
        SELECT 
            s.student_id AS '学号',
            s.name AS '姓名',
            s.gender AS '性别',
            s.birth_date AS '出生日期',
            DATEDIFF(YEAR, s.birth_date, GETDATE()) AS '年龄'
        FROM Students s
        WHERE s.student_id = @user_id;
        
        SELECT 
            COUNT(*) AS '选课总数',
            COUNT(DISTINCT sc.semester) AS '学期数',
            SUM(c.credits) AS '总学分'
        FROM SC sc
        INNER JOIN Courses c ON sc.course_id = c.course_id
        WHERE sc.student_id = @user_id;
    END
    ELSE IF @role = 'teacher'
    BEGIN
        PRINT '=== 教师详细信息 ===';
        SELECT 
            t.teacher_id AS '工号',
            t.name AS '姓名',
            t.department AS '所属部门',
            t.introduction AS '个人简介'
        FROM Teachers t
        WHERE t.teacher_id = @user_id;
        
        SELECT 
            COUNT(DISTINCT tc.course_id) AS '教授课程数',
            COUNT(DISTINCT tc.semester) AS '教学学期数',
            COUNT(DISTINCT sc.student_id) AS '教授学生总数'
        FROM TC tc
        LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                       AND tc.course_id = sc.course_id 
                       AND tc.semester = sc.semester
        WHERE tc.teacher_id = @user_id;
    END
    ELSE IF @role = 'admin'
    BEGIN
        PRINT '=== 管理员信息 ===';
        SELECT '管理员账户' AS '账户类型';
    END
END;

GO
CREATE PROCEDURE sp_get_grades_admin
    @username VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Users WHERE username = @username AND role = 'student')
    BEGIN
        PRINT '用户不存在或不是学生身份';
        RETURN;
    END
    
    -- 查询学生成绩单
    SELECT 
        s.name AS '学生姓名',
        c.course_id AS '课程编号',
        c.name AS '课程名称',
        c.credits AS '学分',
        t.name AS '任课教师',
        sc.semester AS '学期',
        ISNULL(g.score, 0) AS '成绩',
        CASE 
            WHEN g.score IS NULL THEN '未录入'
            WHEN g.score >= 90 THEN '优秀'
            WHEN g.score >= 80 THEN '良好'
            WHEN g.score >= 70 THEN '中等'
            WHEN g.score >= 60 THEN '及格'
            ELSE '不及格'
        END AS '等级'
    FROM Users u
    INNER JOIN Students s ON u.user_id = s.student_id
    INNER JOIN SC sc ON s.student_id = sc.student_id
    INNER JOIN Courses c ON sc.course_id = c.course_id
    INNER JOIN Teachers t ON sc.teacher_id = t.teacher_id
    LEFT JOIN Grades g ON sc.student_id = g.student_id 
                      AND sc.course_id = g.course_id 
                      AND sc.semester = g.semester
    WHERE u.username = @username
    ORDER BY sc.semester DESC, c.course_id;
    
    SELECT 
        COUNT(*) AS '选课总数',
        COUNT(g.score) AS '已录入成绩数',
        COUNT(*) - COUNT(g.score) AS '未录入成绩数',
        ISNULL(AVG(CAST(g.score AS FLOAT)), 0) AS '平均成绩',
        SUM(CASE WHEN g.score >= 60 THEN c.credits ELSE 0 END) AS '已获得学分',
        SUM(c.credits) AS '总学分'
    FROM Users u
    INNER JOIN Students s ON u.user_id = s.student_id
    INNER JOIN SC sc ON s.student_id = sc.student_id
    INNER JOIN Courses c ON sc.course_id = c.course_id
    LEFT JOIN Grades g ON sc.student_id = g.student_id 
                      AND sc.course_id = g.course_id 
                      AND sc.semester = g.semester
    WHERE u.username = @username;
END;

-- 以下为管理员的统计功能
--系统统计
CREATE PROCEDURE sp_admin_get_system_statistics
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        (SELECT COUNT(*) FROM Users) AS '用户总数',
        (SELECT COUNT(*) FROM Users WHERE role = 'student') AS '学生数',
        (SELECT COUNT(*) FROM Users WHERE role = 'teacher') AS '教师数',
        (SELECT COUNT(*) FROM Users WHERE role = 'admin') AS '管理员数',

        (SELECT COUNT(*) FROM Courses) AS '课程总数',
        (SELECT COUNT(DISTINCT course_id) FROM TC) AS '开设课程数',
        (SELECT COUNT(*) FROM TC) AS '教学安排数',
        
        (SELECT COUNT(*) FROM SC) AS '选课总数',
        (SELECT COUNT(DISTINCT student_id) FROM SC) AS '选课学生数',
        (SELECT COUNT(DISTINCT semester) FROM SC) AS '学期数',
        
        (SELECT COUNT(*) FROM Grades) AS '已录成绩数',
        (SELECT COUNT(*) FROM SC WHERE NOT EXISTS (
            SELECT 1 FROM Grades g 
            WHERE g.student_id = SC.student_id 
            AND g.course_id = SC.course_id 
            AND g.semester = SC.semester
        )) AS '未录成绩数',
        
        (SELECT CAST(AVG(CAST(score AS FLOAT)) AS DECIMAL(5,2)) 
         FROM Grades WHERE score IS NOT NULL) AS '平均成绩',
        
        (SELECT CAST(AVG(CAST(credits AS FLOAT)) AS DECIMAL(5,2)) 
         FROM Courses) AS '平均学分',
        CONCAT(
            CAST((SELECT COUNT(*) FROM Grades) * 100.0 / NULLIF((SELECT COUNT(*) FROM SC), 0) AS DECIMAL(5,2)), 
            '%'
        ) AS '成绩录入率';
END;

GO
--课程统计
CREATE PROCEDURE sp_admin_get_course_statistics
    @semester VARCHAR(20) = NULL,  
    @course_id VARCHAR(10) = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.credits,
        sc_stats.semester,
        sc_stats.enrollment_count,
        ISNULL(grade_stats.graded_count, 0) AS graded_count,
        ISNULL(grade_stats.avg_score, 0) AS average_score,
        ISNULL(grade_stats.max_score, 0) AS max_score,
        ISNULL(grade_stats.min_score, 0) AS min_score,
        ISNULL(grade_stats.pass_count, 0) AS pass_count,
        CASE 
            WHEN ISNULL(grade_stats.graded_count, 0) > 0 
            THEN CAST(ISNULL(grade_stats.pass_count, 0) * 100.0 / grade_stats.graded_count AS DECIMAL(5,2))
            ELSE 0 
        END AS pass_rate,
        ISNULL(grade_stats.score_90_100, 0) AS excellent_count,
        ISNULL(grade_stats.score_80_89, 0) AS good_count,
        ISNULL(grade_stats.score_70_79, 0) AS medium_count,
        ISNULL(grade_stats.score_60_69, 0) AS pass_count_detail,
        ISNULL(grade_stats.score_0_59, 0) AS fail_count
    FROM Courses c
    INNER JOIN (
        SELECT 
            course_id,
            semester,
            COUNT(*) AS enrollment_count
        FROM SC
        WHERE (@semester IS NULL OR semester = @semester)
          AND (@course_id IS NULL OR course_id = @course_id)
        GROUP BY course_id, semester
    ) sc_stats ON c.course_id = sc_stats.course_id
    LEFT JOIN (
        SELECT 
            course_id,
            semester,
            COUNT(*) AS graded_count,
            AVG(CAST(score AS FLOAT)) AS avg_score,
            MAX(score) AS max_score,
            MIN(score) AS min_score,
            SUM(CASE WHEN score >= 60 THEN 1 ELSE 0 END) AS pass_count,
            SUM(CASE WHEN score >= 90 THEN 1 ELSE 0 END) AS score_90_100,
            SUM(CASE WHEN score >= 80 AND score <= 89 THEN 1 ELSE 0 END) AS score_80_89,
            SUM(CASE WHEN score >= 70 AND score <= 79 THEN 1 ELSE 0 END) AS score_70_79,
            SUM(CASE WHEN score >= 60 AND score <= 69 THEN 1 ELSE 0 END) AS score_60_69,
            SUM(CASE WHEN score < 60 THEN 1 ELSE 0 END) AS score_0_59
        FROM Grades
        WHERE score IS NOT NULL
          AND (@semester IS NULL OR semester = @semester)
          AND (@course_id IS NULL OR course_id = @course_id)
        GROUP BY course_id, semester
    ) grade_stats ON sc_stats.course_id = grade_stats.course_id 
                 AND sc_stats.semester = grade_stats.semester
    WHERE (@course_id IS NULL OR c.course_id = @course_id)
    ORDER BY c.course_id, sc_stats.semester;
    
    IF @course_id IS NOT NULL
    BEGIN
        SELECT 
            '成绩分布详情' AS detail_type,
            c.name AS course_name,
            g.semester,
            CASE 
                WHEN g.score >= 90 THEN '优秀(90-100)'
                WHEN g.score >= 80 THEN '良好(80-89)'
                WHEN g.score >= 70 THEN '中等(70-79)'
                WHEN g.score >= 60 THEN '及格(60-69)'
                ELSE '不及格(0-59)'
            END AS score_range,
            COUNT(*) AS student_count,
            CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY g.course_id, g.semester) AS DECIMAL(5,2)) AS percentage
        FROM Grades g
        INNER JOIN Courses c ON g.course_id = c.course_id
        WHERE g.score IS NOT NULL
          AND g.course_id = @course_id
          AND (@semester IS NULL OR g.semester = @semester)
        GROUP BY c.name, g.semester, g.course_id,
                 CASE 
                     WHEN g.score >= 90 THEN '优秀(90-100)'
                     WHEN g.score >= 80 THEN '良好(80-89)'
                     WHEN g.score >= 70 THEN '中等(70-79)'
                     WHEN g.score >= 60 THEN '及格(60-69)'
                     ELSE '不及格(0-59)'
                 END
        ORDER BY g.semester, 
                 CASE 
                     WHEN g.score >= 90 THEN 1
                     WHEN g.score >= 80 THEN 2
                     WHEN g.score >= 70 THEN 3
                     WHEN g.score >= 60 THEN 4
                     ELSE 5
                 END;
    END
END;

GO
--学期统计
CREATE PROCEDURE sp_admin_get_semester_statistics
    @semester VARCHAR(20) = NULL  
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 学期选课和成绩统计概览
    SELECT 
        semester_stats.semester,
        semester_stats.total_enrollments,
        semester_stats.total_courses_offered,
        semester_stats.total_students_enrolled,
        ISNULL(grade_stats.total_graded, 0) AS total_graded,
        ISNULL(grade_stats.avg_score, 0) AS semester_avg_score,
        ISNULL(grade_stats.pass_count, 0) AS total_pass_count,
        CASE 
            WHEN ISNULL(grade_stats.total_graded, 0) > 0 
            THEN CAST(ISNULL(grade_stats.pass_count, 0) * 100.0 / grade_stats.total_graded AS DECIMAL(5,2))
            ELSE 0 
        END AS semester_pass_rate,
        ISNULL(grade_stats.excellent_count, 0) AS excellent_count,
        ISNULL(grade_stats.good_count, 0) AS good_count,
        ISNULL(grade_stats.medium_count, 0) AS medium_count,
        ISNULL(grade_stats.pass_only_count, 0) AS pass_only_count,
        ISNULL(grade_stats.fail_count, 0) AS fail_count
    FROM (
        -- 选课统计
        SELECT 
            sc.semester,
            COUNT(*) AS total_enrollments,
            COUNT(DISTINCT sc.course_id) AS total_courses_offered,
            COUNT(DISTINCT sc.student_id) AS total_students_enrolled
        FROM SC sc
        WHERE (@semester IS NULL OR sc.semester = @semester)
        GROUP BY sc.semester
    ) semester_stats
    LEFT JOIN (
        -- 成绩统计
        SELECT 
            g.semester,
            COUNT(*) AS total_graded,
            AVG(CAST(g.score AS FLOAT)) AS avg_score,
            SUM(CASE WHEN g.score >= 60 THEN 1 ELSE 0 END) AS pass_count,
            SUM(CASE WHEN g.score >= 90 THEN 1 ELSE 0 END) AS excellent_count,
            SUM(CASE WHEN g.score >= 80 AND g.score <= 89 THEN 1 ELSE 0 END) AS good_count,
            SUM(CASE WHEN g.score >= 70 AND g.score <= 79 THEN 1 ELSE 0 END) AS medium_count,
            SUM(CASE WHEN g.score >= 60 AND g.score <= 69 THEN 1 ELSE 0 END) AS pass_only_count,
            SUM(CASE WHEN g.score < 60 THEN 1 ELSE 0 END) AS fail_count
        FROM Grades g
        WHERE g.score IS NOT NULL
          AND (@semester IS NULL OR g.semester = @semester)
        GROUP BY g.semester
    ) grade_stats ON semester_stats.semester = grade_stats.semester
    ORDER BY semester_stats.semester;
    
    -- 学期课程详细统计
    SELECT 
        '课程详细统计' AS detail_type,
        sc.semester,
        c.course_id,
        c.name AS course_name,
        c.credits,
        COUNT(sc.student_id) AS enrollment_count,
        ISNULL(course_grades.graded_count, 0) AS graded_count,
        ISNULL(course_grades.avg_score, 0) AS course_avg_score,
        ISNULL(course_grades.max_score, 0) AS max_score,
        ISNULL(course_grades.min_score, 0) AS min_score,
        ISNULL(course_grades.pass_count, 0) AS pass_count,
        CASE 
            WHEN ISNULL(course_grades.graded_count, 0) > 0 
            THEN CAST(ISNULL(course_grades.pass_count, 0) * 100.0 / course_grades.graded_count AS DECIMAL(5,2))
            ELSE 0 
        END AS course_pass_rate
    FROM SC sc
    INNER JOIN Courses c ON sc.course_id = c.course_id
    LEFT JOIN (
        SELECT 
            course_id,
            semester,
            COUNT(*) AS graded_count,
            AVG(CAST(score AS FLOAT)) AS avg_score,
            MAX(score) AS max_score,
            MIN(score) AS min_score,
            SUM(CASE WHEN score >= 60 THEN 1 ELSE 0 END) AS pass_count
        FROM Grades
        WHERE score IS NOT NULL
          AND (@semester IS NULL OR semester = @semester)
        GROUP BY course_id, semester
    ) course_grades ON sc.course_id = course_grades.course_id 
                   AND sc.semester = course_grades.semester
    WHERE (@semester IS NULL OR sc.semester = @semester)
    GROUP BY sc.semester, c.course_id, c.name, c.credits,
             course_grades.graded_count, course_grades.avg_score,
             course_grades.max_score, course_grades.min_score, course_grades.pass_count
    ORDER BY sc.semester, c.course_id;
    
    -- 学期学生参与度统计
    SELECT 
        '学生参与度统计' AS detail_type,
        student_stats.semester,
        student_stats.total_students,
        student_stats.avg_courses_per_student,
        student_stats.max_courses_per_student,
        student_stats.min_courses_per_student,
        ISNULL(student_performance.students_with_grades, 0) AS students_with_grades,
        ISNULL(student_performance.avg_student_score, 0) AS avg_student_score,
        ISNULL(student_performance.students_all_pass, 0) AS students_all_pass,
        CASE 
            WHEN ISNULL(student_performance.students_with_grades, 0) > 0 
            THEN CAST(ISNULL(student_performance.students_all_pass, 0) * 100.0 / student_performance.students_with_grades AS DECIMAL(5,2))
            ELSE 0 
        END AS students_all_pass_rate
    FROM (
        -- 学生选课统计
        SELECT 
            sc.semester,
            COUNT(DISTINCT sc.student_id) AS total_students,
            AVG(CAST(course_count.courses_per_student AS FLOAT)) AS avg_courses_per_student,
            MAX(course_count.courses_per_student) AS max_courses_per_student,
            MIN(course_count.courses_per_student) AS min_courses_per_student
        FROM SC sc
        INNER JOIN (
            SELECT student_id, semester, COUNT(*) AS courses_per_student
            FROM SC
            WHERE (@semester IS NULL OR semester = @semester)
            GROUP BY student_id, semester
        ) course_count ON sc.student_id = course_count.student_id 
                      AND sc.semester = course_count.semester
        WHERE (@semester IS NULL OR sc.semester = @semester)
        GROUP BY sc.semester
    ) student_stats
    LEFT JOIN (
        -- 学生成绩表现统计
        SELECT 
            student_perf.semester,
            COUNT(DISTINCT student_perf.student_id) AS students_with_grades,
            AVG(student_perf.avg_score) AS avg_student_score,
            SUM(CASE WHEN student_perf.min_score >= 60 THEN 1 ELSE 0 END) AS students_all_pass
        FROM (
            SELECT 
                g.student_id,
                g.semester,
                AVG(CAST(g.score AS FLOAT)) AS avg_score,
                MIN(g.score) AS min_score
            FROM Grades g
            WHERE g.score IS NOT NULL
              AND (@semester IS NULL OR g.semester = @semester)
            GROUP BY g.student_id, g.semester
        ) student_perf
        GROUP BY student_perf.semester
    ) student_performance ON student_stats.semester = student_performance.semester
    ORDER BY student_stats.semester;
    
    -- 学期教师工作量统计
    SELECT 
        '教师工作量统计' AS detail_type,
        tc.semester,
        COUNT(DISTINCT tc.teacher_id) AS total_teachers,
        COUNT(DISTINCT tc.course_id) AS total_courses_taught,
        AVG(CAST(teacher_workload.courses_per_teacher AS FLOAT)) AS avg_courses_per_teacher,
        AVG(CAST(teacher_workload.students_per_teacher AS FLOAT)) AS avg_students_per_teacher,
        SUM(teacher_workload.students_per_teacher) AS total_teaching_load
    FROM TC tc
    INNER JOIN (
        SELECT 
            tc.teacher_id,
            tc.semester,
            COUNT(DISTINCT tc.course_id) AS courses_per_teacher,
            COUNT(sc.student_id) AS students_per_teacher
        FROM TC tc
        LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                       AND tc.course_id = sc.course_id 
                       AND tc.semester = sc.semester
        WHERE (@semester IS NULL OR tc.semester = @semester)
        GROUP BY tc.teacher_id, tc.semester
    ) teacher_workload ON tc.teacher_id = teacher_workload.teacher_id 
                      AND tc.semester = teacher_workload.semester
    WHERE (@semester IS NULL OR tc.semester = @semester)
    GROUP BY tc.semester
    ORDER BY tc.semester;
END;

GO
--教师工作量统计 - 教师教授课程数、学生数
CREATE PROCEDURE sp_admin_get_teacher_statistics
    @semester VARCHAR(20) = NULL,    
    @teacher_id VARCHAR(10) = NULL, 
    @department VARCHAR(50) = NULL   
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 教师工作量统计主表
    SELECT 
        t.teacher_id,
        t.name AS teacher_name,
        t.department,
        workload.semester,
        workload.courses_taught,
        workload.total_students,
        workload.total_credits,
        workload.avg_students_per_course,
        ISNULL(grade_stats.graded_students, 0) AS graded_students,
        ISNULL(grade_stats.avg_score, 0) AS teacher_avg_score,
        ISNULL(grade_stats.pass_count, 0) AS students_passed,
        CASE 
            WHEN ISNULL(grade_stats.graded_students, 0) > 0 
            THEN CAST(ISNULL(grade_stats.pass_count, 0) * 100.0 / grade_stats.graded_students AS DECIMAL(5,2))
            ELSE 0 
        END AS pass_rate
    FROM Teachers t
    INNER JOIN (
        -- 教师工作量基础统计
        SELECT 
            tc.teacher_id,
            tc.semester,
            COUNT(DISTINCT tc.course_id) AS courses_taught,
            COUNT(sc.student_id) AS total_students,
            SUM(c.credits) AS total_credits,
            CASE 
                WHEN COUNT(DISTINCT tc.course_id) > 0 
                THEN CAST(COUNT(sc.student_id) AS FLOAT) / COUNT(DISTINCT tc.course_id)
                ELSE 0 
            END AS avg_students_per_course
        FROM TC tc
        LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                       AND tc.course_id = sc.course_id 
                       AND tc.semester = sc.semester
        LEFT JOIN Courses c ON tc.course_id = c.course_id
        WHERE (@semester IS NULL OR tc.semester = @semester)
          AND (@teacher_id IS NULL OR tc.teacher_id = @teacher_id)
        GROUP BY tc.teacher_id, tc.semester
    ) workload ON t.teacher_id = workload.teacher_id
    LEFT JOIN (
        -- 教师教学成绩统计
        SELECT 
            tc.teacher_id,
            tc.semester,
            COUNT(g.student_id) AS graded_students,
            AVG(CAST(g.score AS FLOAT)) AS avg_score,
            SUM(CASE WHEN g.score >= 60 THEN 1 ELSE 0 END) AS pass_count
        FROM TC tc
        INNER JOIN Grades g ON tc.course_id = g.course_id AND tc.semester = g.semester
        WHERE g.score IS NOT NULL
          AND (@semester IS NULL OR tc.semester = @semester)
          AND (@teacher_id IS NULL OR tc.teacher_id = @teacher_id)
        GROUP BY tc.teacher_id, tc.semester
    ) grade_stats ON workload.teacher_id = grade_stats.teacher_id 
                 AND workload.semester = grade_stats.semester
    WHERE (@department IS NULL OR t.department = @department)
      AND (@teacher_id IS NULL OR t.teacher_id = @teacher_id)
    ORDER BY workload.semester, t.department, t.teacher_id;
    
    -- 教师课程详细信息
    SELECT 
        '课程详细信息' AS detail_type,
        t.teacher_id,
        t.name AS teacher_name,
        t.department,
        tc.semester,
        c.course_id,
        c.name AS course_name,
        c.credits,
        COUNT(sc.student_id) AS enrolled_students,
        ISNULL(course_grades.graded_count, 0) AS graded_students,
        ISNULL(course_grades.avg_score, 0) AS course_avg_score,
        ISNULL(course_grades.max_score, 0) AS max_score,
        ISNULL(course_grades.min_score, 0) AS min_score,
        ISNULL(course_grades.pass_count, 0) AS pass_count,
        CASE 
            WHEN ISNULL(course_grades.graded_count, 0) > 0 
            THEN CAST(ISNULL(course_grades.pass_count, 0) * 100.0 / course_grades.graded_count AS DECIMAL(5,2))
            ELSE 0 
        END AS course_pass_rate
    FROM Teachers t
    INNER JOIN TC tc ON t.teacher_id = tc.teacher_id
    INNER JOIN Courses c ON tc.course_id = c.course_id
    LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                   AND tc.course_id = sc.course_id 
                   AND tc.semester = sc.semester
    LEFT JOIN (
        SELECT 
            course_id,
            semester,
            COUNT(*) AS graded_count,
            AVG(CAST(score AS FLOAT)) AS avg_score,
            MAX(score) AS max_score,
            MIN(score) AS min_score,
            SUM(CASE WHEN score >= 60 THEN 1 ELSE 0 END) AS pass_count
        FROM Grades
        WHERE score IS NOT NULL
          AND (@semester IS NULL OR semester = @semester)
        GROUP BY course_id, semester
    ) course_grades ON tc.course_id = course_grades.course_id 
                   AND tc.semester = course_grades.semester
    WHERE (@semester IS NULL OR tc.semester = @semester)
      AND (@teacher_id IS NULL OR t.teacher_id = @teacher_id)
      AND (@department IS NULL OR t.department = @department)
    GROUP BY t.teacher_id, t.name, t.department, tc.semester, 
             c.course_id, c.name, c.credits,
             course_grades.graded_count, course_grades.avg_score,
             course_grades.max_score, course_grades.min_score, course_grades.pass_count
    ORDER BY tc.semester, t.department, t.teacher_id, c.course_id;
    
    -- 院系工作量汇总统计
    SELECT 
        '院系工作量汇总' AS summary_type,
        dept_stats.department,
        dept_stats.semester,
        dept_stats.total_teachers,
        dept_stats.total_courses,
        dept_stats.total_students,
        dept_stats.total_credits,
        dept_stats.avg_courses_per_teacher,
        dept_stats.avg_students_per_teacher,
        dept_stats.avg_credits_per_teacher
    FROM (
        SELECT 
            t.department,
            tc.semester,
            COUNT(DISTINCT t.teacher_id) AS total_teachers,
            COUNT(DISTINCT tc.course_id) AS total_courses,
            COUNT(sc.student_id) AS total_students,
            SUM(c.credits) AS total_credits,
            CAST(COUNT(DISTINCT tc.course_id) AS FLOAT) / COUNT(DISTINCT t.teacher_id) AS avg_courses_per_teacher,
            CAST(COUNT(sc.student_id) AS FLOAT) / COUNT(DISTINCT t.teacher_id) AS avg_students_per_teacher,
            CAST(SUM(c.credits) AS FLOAT) / COUNT(DISTINCT t.teacher_id) AS avg_credits_per_teacher
        FROM Teachers t
        INNER JOIN TC tc ON t.teacher_id = tc.teacher_id
        LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                       AND tc.course_id = sc.course_id 
                       AND tc.semester = sc.semester
        LEFT JOIN Courses c ON tc.course_id = c.course_id
        WHERE (@semester IS NULL OR tc.semester = @semester)
          AND (@department IS NULL OR t.department = @department)
        GROUP BY t.department, tc.semester
    ) dept_stats
    ORDER BY dept_stats.semester, dept_stats.department;
    
    -- 工作量排名统计
    IF @semester IS NOT NULL
    BEGIN
        SELECT 
            '工作量排名' AS ranking_type,
            @semester AS semester,
            t.teacher_id,
            t.name AS teacher_name,
            t.department,
            workload_rank.courses_taught,
            workload_rank.total_students,
            workload_rank.total_credits,
            ROW_NUMBER() OVER (ORDER BY workload_rank.total_students DESC) AS student_count_rank,
            ROW_NUMBER() OVER (ORDER BY workload_rank.courses_taught DESC) AS course_count_rank,
            ROW_NUMBER() OVER (ORDER BY workload_rank.total_credits DESC) AS credit_count_rank
        FROM Teachers t
        INNER JOIN (
            SELECT 
                tc.teacher_id,
                COUNT(DISTINCT tc.course_id) AS courses_taught,
                COUNT(sc.student_id) AS total_students,
                SUM(c.credits) AS total_credits
            FROM TC tc
            LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                           AND tc.course_id = sc.course_id 
                           AND tc.semester = sc.semester
            LEFT JOIN Courses c ON tc.course_id = c.course_id
            WHERE tc.semester = @semester
              AND (@department IS NULL OR EXISTS (
                  SELECT 1 FROM Teachers t2 
                  WHERE t2.teacher_id = tc.teacher_id 
                    AND (@department IS NULL OR t2.department = @department)
              ))
            GROUP BY tc.teacher_id
        ) workload_rank ON t.teacher_id = workload_rank.teacher_id
        WHERE (@department IS NULL OR t.department = @department)
        ORDER BY workload_rank.total_students DESC, workload_rank.courses_taught DESC;
    END
END;

GO
--统计学生信息
CREATE PROCEDURE sp_admin_get_student_stastic
    @student_id VARCHAR(10) = NULL,   
    @semester VARCHAR(20) = NULL      
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        s.student_id,
        s.name AS student_name,
        ISNULL(academic_stats.semester, '累计') AS semester,
        ISNULL(academic_stats.total_credits, 0) AS total_credits,
        ISNULL(academic_stats.completed_credits, 0) AS completed_credits,
        ISNULL(academic_stats.gpa, 0.00) AS gpa
    FROM Students s
    LEFT JOIN (
        SELECT 
            sc.student_id,
            CASE WHEN @semester IS NOT NULL THEN sc.semester ELSE NULL END AS semester,
            SUM(c.credits) AS total_credits,
            SUM(CASE WHEN g.score IS NOT NULL THEN c.credits ELSE 0 END) AS completed_credits,
            -- GPA计算 (4.0制度)
            CASE 
                WHEN SUM(CASE WHEN g.score IS NOT NULL THEN c.credits ELSE 0 END) > 0 
                THEN CAST(SUM(CASE 
                    WHEN g.score >= 90 THEN c.credits * 4.0
                    WHEN g.score >= 80 THEN c.credits * 3.0
                    WHEN g.score >= 70 THEN c.credits * 2.0
                    WHEN g.score >= 60 THEN c.credits * 1.0
                    WHEN g.score IS NOT NULL THEN c.credits * 0.0
                    ELSE 0
                END) / SUM(CASE WHEN g.score IS NOT NULL THEN c.credits ELSE 0 END) AS DECIMAL(3,2))
                ELSE 0.00 
            END AS gpa
        FROM SC sc
        INNER JOIN Courses c ON sc.course_id = c.course_id
        LEFT JOIN Grades g ON sc.student_id = g.student_id 
                          AND sc.course_id = g.course_id 
                          AND sc.semester = g.semester
        WHERE (@student_id IS NULL OR sc.student_id = @student_id)
          AND (@semester IS NULL OR sc.semester = @semester)
        GROUP BY sc.student_id, 
                 CASE WHEN @semester IS NOT NULL THEN sc.semester ELSE NULL END
    ) academic_stats ON s.student_id = academic_stats.student_id
    WHERE (@student_id IS NULL OR s.student_id = @student_id)
      AND academic_stats.student_id IS NOT NULL 
    ORDER BY s.student_id, academic_stats.semester;
END;
