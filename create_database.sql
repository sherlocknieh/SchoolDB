USE master;
GO
DROP DATABASE School;     -- 删除 School 数据库
GO
CREATE DATABASE School;   -- 创建 School 数据库
GO
USE School;
GO

-- 用户表（统一存储学生、教师、管理员）
-- 使用username当做user使用
CREATE TABLE Users (
    id VARCHAR(10) PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('student', 'teacher', 'admin'))
);

-- 学生信息表
CREATE TABLE Students (
    student_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(10),
    birth_date DATE,
    FOREIGN KEY (student_id) REFERENCES Users(id) ON DELETE CASCADE
);

-- 教师信息表
CREATE TABLE Teachers (
    teacher_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    introduction TEXT,
    FOREIGN KEY (teacher_id) REFERENCES Users(id) ON DELETE CASCADE
);

-- 课程信息表
CREATE TABLE Courses (
    course_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT, 
    credits INT NOT NULL
);

-- 成绩表
CREATE TABLE Grades (
    student_id VARCHAR(10) NOT NULL,
    course_id VARCHAR(10) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    score INT CHECK (score BETWEEN 0 AND 100),
    FOREIGN KEY (student_id, course_id, semester) REFERENCES SC(student_id, course_id, semester) ON DELETE CASCADE,
    PRIMARY KEY (student_id, course_id, semester)
);

-- 教师教授信息
CREATE TABLE TC (
    teacher_id VARCHAR(10) NOT NULL,
    course_id VARCHAR(10) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES Teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    PRIMARY KEY (teacher_id, course_id, semester)
);

--选课表
--选课表需要与成绩表独立
CREATE TABLE SC (
    student_id VARCHAR(10) NOT NULL,
    teacher_id VARCHAR(10) NOT NULL,
    course_id VARCHAR(10) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id, course_id, semester) REFERENCES TC(teacher_id, course_id, semester) ON DELETE CASCADE,
    PRIMARY KEY (student_id, course_id, semester)
);

--权限管理
--创建角色
CREATE ROLE admin_role;
CREATE ROLE teacher_role;
CREATE ROLE student_role;

--授予权限
--管理员
GRANT ALL PRIVILEGES ON ALL TABLES TO admin_role;
GRANT CREATE USER, CREATE ROLE, GRANT ANY ROLE TO admin_role WITH ADMIN OPTION;

--教师
--三个view代表查询自己个人信息、查询自己的账号信息、查询成绩信息
--成绩信息应该查看学生姓名、课程名、成绩、学分
CREATE VIEW V_Teacher_Info AS
SELECT t.teacher_id, t.name, t.department, t.introduction
FROM Teachers t JOIN Users u ON t.teacher_id = u.id
WHERE u.username = CURRENT_USER;

CREATE VIEW V_User_Self AS
SELECT id, username, password, role FROM Users WHERE username = CURRENT_USER;

CREATE VIEW V_Teacher_Grades AS
SELECT st.name AS student_name, st.student_id, c.name AS course_name, g.score, c.credits, g.semester
FROM Grades g
JOIN SC sc ON g.student_id = sc.student_id AND g.course_id = sc.course_id AND g.semester = sc.semester
JOIN Courses c ON g.course_id = c.course_id
JOIN Students st ON g.student_id = st.student_id
JOIN Users u ON sc.teacher_id = u.id
WHERE u.username = CURRENT_USER;

CREATE VIEW V_Teacher_Courses AS
SELECT c.course_id, c.name, c.description, c.credits, tc.semester
FROM TC tc
JOIN Courses c ON tc.course_id = c.course_id
JOIN Users u ON tc.teacher_id = u.id
WHERE u.username = CURRENT_USER;

-- 账号信息只能改密码，个人信息不可以改用户名和id号
GRANT SELECT, UPDATE(department, introduction) ON V_Teacher_Info TO teacher_role;
GRANT SELECT, UPDATE(password) ON V_User_Self TO teacher_role;
GRANT SELECT ON V_Teacher_Courses TO teacher_role;
GRANT SELECT, INSERT, UPDATE ON V_Teacher_Grades TO teacher_role; 
GRANT SELECT ON Students TO teacher_role; 
GRANT SELECT ON Courses TO teacher_role; 

--学生
--成绩信息：姓名、学号、学期、课程、成绩、学分
CREATE VIEW V_Student_Info AS
SELECT s.student_id, s.name, s.gender, s.birth_date
FROM Students s JOIN Users u ON s.student_id = u.id
WHERE u.username = CURRENT_USER;

CREATE VIEW V_Student_Grades AS
SELECT c.name AS course_name, g.semester, g.score, c.credits,
       CASE WHEN g.score >= 60 THEN '是' ELSE '否' END AS is_pass
FROM Grades g
JOIN Courses c ON g.course_id = c.course_id
JOIN Users u ON g.student_id = u.id
WHERE u.username = CURRENT_USER;

CREATE VIEW V_Student_SC AS
SELECT c.name AS course_name, t.name as teacher_name, sc.semester, c.credits
FROM SC sc
JOIN Courses c ON sc.course_id = c.course_id
JOIN Teachers t ON sc.teacher_id = t.teacher_id
JOIN Users u ON sc.student_id = u.id
WHERE u.username = CURRENT_USER;


GRANT SELECT, UPDATE(gender, birth_date) ON V_Student_Info TO student_role;
GRANT SELECT, UPDATE(password) ON V_User_Self TO student_role;
GRANT SELECT ON V_Student_Grades TO student_role;
GRANT SELECT ON V_Student_SC TO student_role;
GRANT SELECT ON Courses TO student_role;
GRANT SELECT ON TC TO student_role;


--以下是存储过程
--为图方便和安全性，一切插入过程应该由存储过程来实现

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
    INSERT INTO Users (id, username, password, role)
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



-- 存储过程：管理员安排教学任务
CREATE PROCEDURE sp_add_tc
    @p_teacher_id VARCHAR(10),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Teachers WHERE teacher_id = @p_teacher_id)
        BEGIN
            DECLARE @error_msg1 VARCHAR(200) = '安排失败：教师ID(' + @p_teacher_id + ')不存在。';
            THROW 50001, @error_msg1, 1;
        END

        IF NOT EXISTS (SELECT 1 FROM Courses WHERE course_id = @p_course_id)
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
    
    SELECT @v_teacher_id = id FROM Users WHERE username = @p_teacher_username AND role = 'teacher';
    IF @v_teacher_id IS NULL
    BEGIN
        THROW 50005, '操作失败：当前用户不是教师或用户不存在。', 1;
    END

    IF NOT EXISTS (
        SELECT 1 FROM TC
        WHERE teacher_id = @v_teacher_id AND course_id = @p_course_id AND semester = @p_semester
    )
    BEGIN
        THROW 50006, '权限不足：您未在本学期教授此课程。', 1;
    END
    
    IF NOT EXISTS (
        SELECT 1 FROM SC
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


-- 存储过程：教师更新自己的个人信息 
CREATE PROCEDURE sp_teacher_update_profile
    @p_teacher_username VARCHAR(50),
    @p_department VARCHAR(50),
    @p_introduction TEXT
AS
BEGIN
    BEGIN TRY
        DECLARE @v_teacher_id VARCHAR(10);
        
        SELECT @v_teacher_id = id FROM Users WHERE username = @p_teacher_username AND role = 'teacher';
        IF @v_teacher_id IS NULL
        BEGIN
            DECLARE @error_msg VARCHAR(200) = '操作失败：用户(' + @p_teacher_username + ')不是教师或不存在。';
            THROW 50008, @error_msg, 1;
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
        DECLARE @error_msg VARCHAR(200) = '更新教师信息失败: ' + ERROR_MESSAGE();
        THROW 50009, @error_msg, 1;
    END CATCH
END;


--学生
--选课
CREATE PROCEDURE sp_student_select_course
    @p_student_username VARCHAR(50),
    @p_teacher_id VARCHAR(10),
    @p_course_id VARCHAR(10),
    @p_semester VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        DECLARE @v_student_id VARCHAR(10);
        
        SELECT @v_student_id = id FROM Users WHERE username = @p_student_username AND role = 'student';
        IF @v_student_id IS NULL
        BEGIN
            THROW 50010, '操作失败：当前用户不是学生或用户不存在。', 1;
        END

        IF NOT EXISTS (
            SELECT 1 FROM TC
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

-- 存储过程：学生更新自己的个人信息
CREATE PROCEDURE sp_student_update_profile
    @p_student_username VARCHAR(50),
    @p_gender VARCHAR(10),
    @p_birth_date DATE
AS
BEGIN
    BEGIN TRY
        DECLARE @v_student_id VARCHAR(10);
        
        SELECT @v_student_id = id FROM Users WHERE username = @p_student_username AND role = 'student';
        IF @v_student_id IS NULL
        BEGIN
            DECLARE @error_msg VARCHAR(200) = '操作失败：用户(' + @p_student_username + ')不是学生或不存在。';
            THROW 50014, @error_msg, 1;
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
        DECLARE @error_msg VARCHAR(200) = '更新学生信息失败: ' + ERROR_MESSAGE();
        THROW 50015, @error_msg, 1;
    END CATCH
END;


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
        
        SELECT @v_student_id = id FROM Users WHERE username = @p_student_username AND role = 'student';
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

--触发器设置
--使用存储过程来实现对表的插入删除，所以触发器应该用来检查违规操作
CREATE TRIGGER trg_before_student_drop_course
ON SC
FOR DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Grades g
        INNER JOIN deleted d ON g.student_id = d.student_id 
            AND g.course_id = d.course_id 
            AND g.semester = d.semester
        WHERE g.score IS NOT NULL
    )
    BEGIN
        THROW 50000, '退课失败：该课程已有成绩录入，无法退选。', 1;
    END
    ELSE
    BEGIN
        DELETE FROM SC 
        WHERE EXISTS (
            SELECT 1 FROM deleted d 
            WHERE SC.student_id = d.student_id 
                AND SC.course_id = d.course_id 
                AND SC.semester = d.semester
        );
    END
END