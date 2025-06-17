--此处为公用，所有角色都可以调用，同时保持触发器作为约束
/*
sp_update_password - 修改用户密码
sp_get_course_detail_public - 查询课程详细信息
sp_get_course_info_public - 课程信息查询
*/
GO
-- 存储过程：任何用户修改自己的密码
CREATE PROCEDURE sp_update_password
    @p_username VARCHAR(50),
    @p_old_password VARCHAR(100),
    @p_new_password VARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @v_current_password VARCHAR(100);
        
        SELECT @v_current_password = password FROM Users WHERE username = @p_username;
        IF @v_current_password IS NULL
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '操作失败：用户(' + @p_username + ')不存在。';
            THROW 50019, @error_msg1, 1;
        END

        IF @v_current_password <> @p_old_password
        BEGIN
            THROW 50020, '密码修改失败：旧密码不正确。', 1;
        END
        
        UPDATE Users
        SET password = @p_new_password
        WHERE username = @p_username;
        
        DECLARE @success_msg VARCHAR(200) = '用户(' + @p_username + ')的密码已成功修改。';
        PRINT @success_msg;
    END TRY
    BEGIN CATCH
        DECLARE @error_msg VARCHAR(200) = '修改密码时发生未知错误: ' + ERROR_MESSAGE();
        THROW 50021, @error_msg, 1;
    END CATCH
END;

GO
--查询课程信息
CREATE PROCEDURE sp_get_course_detail_public
    @course_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 检查课程是否存在
    IF NOT EXISTS (SELECT * FROM Courses WHERE course_id = @course_id)
    BEGIN
        PRINT '课程不存在';
        RETURN;
    END
    
    -- 显示课程基本信息
    PRINT '=== 课程基本信息 ===';
    SELECT 
        course_id AS '课程编号',
        name AS '课程名称',
        description AS '课程描述',
        credits AS '学分'
    FROM Courses 
    WHERE course_id = @course_id;
    
    -- 显示授课教师信息
    PRINT '=== 授课教师信息 ===';
    SELECT 
        t.teacher_id AS '教师工号',
        t.name AS '教师姓名',
        t.department AS '所属部门',
        tc.semester AS '授课学期',
        COUNT(sc.student_id) AS '该学期选课人数'
    FROM TC tc
    INNER JOIN Teachers t ON tc.teacher_id = t.teacher_id
    LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                   AND tc.course_id = sc.course_id 
                   AND tc.semester = sc.semester
    WHERE tc.course_id = @course_id
    GROUP BY t.teacher_id, t.name, t.department, tc.semester
    ORDER BY tc.semester DESC;
    
    -- 显示选课统计
    PRINT '=== 选课统计信息 ===';
    SELECT 
        COUNT(DISTINCT tc.semester) AS '开设学期总数',
        COUNT(DISTINCT tc.teacher_id) AS '授课教师总数',
        COUNT(DISTINCT sc.student_id) AS '选课学生总数',
        ISNULL(AVG(CAST(g.score AS FLOAT)), 0) AS '平均成绩'
    FROM TC tc
    LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                   AND tc.course_id = sc.course_id 
                   AND tc.semester = sc.semester
    LEFT JOIN Grades g ON sc.student_id = g.student_id 
                      AND sc.course_id = g.course_id 
                      AND sc.semester = g.semester
    WHERE tc.course_id = @course_id;
END;

GO
CREATE PROCEDURE sp_get_course_info_public
    @course_id VARCHAR(10) = NULL,          
    @course_name VARCHAR(100) = NULL,        
    @teacher_name VARCHAR(50) = NULL,      
    @semester VARCHAR(20) = NULL,          
    @min_credits INT = NULL,               
    @max_credits INT = NULL                 
AS
BEGIN
    SET NOCOUNT ON;
    
    IF (@course_id IS NULL AND @course_name IS NULL AND @teacher_name IS NULL 
        AND @semester IS NULL AND @min_credits IS NULL AND @max_credits IS NULL)
    BEGIN
        SELECT 
            c.course_id AS '课程编号',
            c.name AS '课程名称',
            c.description AS '课程描述',
            c.credits AS '学分',
            COUNT(DISTINCT tc.teacher_id) AS '授课教师数',
            COUNT(DISTINCT tc.semester) AS '开设学期数'
        FROM Courses c
        LEFT JOIN TC tc ON c.course_id = tc.course_id
        GROUP BY c.course_id, c.name, c.description, c.credits
        ORDER BY c.course_id;
        RETURN;
    END
    
    SELECT DISTINCT
        c.course_id AS '课程编号',
        c.name AS '课程名称',
        c.description AS '课程描述',
        c.credits AS '学分',
        t.name AS '授课教师',
        t.department AS '教师所属部门',
        tc.semester AS '开设学期',
        COUNT(sc.student_id) AS '选课人数'
    FROM Courses c
    LEFT JOIN TC tc ON c.course_id = tc.course_id
    LEFT JOIN Teachers t ON tc.teacher_id = t.teacher_id
    LEFT JOIN SC sc ON tc.teacher_id = sc.teacher_id 
                   AND tc.course_id = sc.course_id 
                   AND tc.semester = sc.semester
    WHERE 
        (@course_id IS NULL OR c.course_id = @course_id)
        AND (@course_name IS NULL OR c.name LIKE '%' + @course_name + '%')
        AND (@teacher_name IS NULL OR t.name LIKE '%' + @teacher_name + '%')
        AND (@semester IS NULL OR tc.semester = @semester)
        AND (@min_credits IS NULL OR c.credits >= @min_credits)
        AND (@max_credits IS NULL OR c.credits <= @max_credits)
    GROUP BY c.course_id, c.name, c.description, c.credits, 
             t.name, t.department, tc.semester
    ORDER BY c.course_id, tc.semester;
    
    PRINT '=== 查询统计信息 ===';
    SELECT 
        COUNT(DISTINCT c.course_id) AS '符合条件的课程数',
        AVG(CAST(c.credits AS FLOAT)) AS '平均学分',
        MIN(c.credits) AS '最低学分',
        MAX(c.credits) AS '最高学分'
    FROM Courses c
    LEFT JOIN TC tc ON c.course_id = tc.course_id
    LEFT JOIN Teachers t ON tc.teacher_id = t.teacher_id
    WHERE 
        (@course_id IS NULL OR c.course_id = @course_id)
        AND (@course_name IS NULL OR c.name LIKE '%' + @course_name + '%')
        AND (@teacher_name IS NULL OR t.name LIKE '%' + @teacher_name + '%')
        AND (@semester IS NULL OR tc.semester = @semester)
        AND (@min_credits IS NULL OR c.credits >= @min_credits)
        AND (@max_credits IS NULL OR c.credits <= @max_credits);
END;


GO
--触发器设置
--使用存储过程来实现对表的插入删除，所以触发器应该用来检查违规操作
CREATE TRIGGER trg_prevent_drop_with_grades
ON SC
FOR DELETE
AS
BEGIN
    IF EXISTS (
        SELECT *
        FROM Grades g
        INNER JOIN deleted d ON g.student_id = d.student_id 
            AND g.course_id = d.course_id 
            AND g.semester = d.semester
        WHERE g.score IS NOT NULL
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50000, '退课失败：该课程已有成绩录入，无法退选。', 1;
    END
END
