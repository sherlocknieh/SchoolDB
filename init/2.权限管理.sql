USE SchoolDB;
GO

-- --权限管理
-- --创建角色
-- CREATE ROLE admin_role;
-- CREATE ROLE teacher_role;
-- CREATE ROLE student_role;

GO
--授予权限
--管理员
GRANT ALL PRIVILEGES ON ALL TABLES TO admin_role;

GRANT CREATE USER, CREATE ROLE, 
 ANY ROLE TO admin_role WITH ADMIN OPTION;

-- GO
-- --教师
-- --三个view代表查询自己个人信息、查询自己的账号信息、查询成绩信息
-- --成绩信息应该查看学生姓名、课程名、成绩、学分
-- CREATE VIEW V_Teacher_Info AS
-- SELECT t.teacher_id, t.name, t.department, t.introduction
-- FROM Teachers t JOIN Users u ON t.teacher_id = u.id
-- WHERE u.username = CURRENT_USER;

-- GO
-- CREATE VIEW V_User_Self AS
-- SELECT id, username, password, role FROM Users WHERE username = CURRENT_USER;


-- GO
-- CREATE VIEW V_Teacher_Grades AS
-- SELECT st.name AS student_name, st.student_id, c.name AS course_name, g.score, c.credits, g.semester
-- FROM Grades g
-- JOIN SC sc ON g.student_id = sc.student_id AND g.course_id = sc.course_id AND g.semester = sc.semester
-- JOIN Courses c ON g.course_id = c.course_id
-- JOIN Students st ON g.student_id = st.student_id
-- JOIN Users u ON sc.teacher_id = u.id
-- WHERE u.username = CURRENT_USER;

-- GO

-- CREATE VIEW V_Teacher_Courses AS
-- SELECT c.course_id, c.name, c.description, c.credits, tc.semester
-- FROM TC tc
-- JOIN Courses c ON tc.course_id = c.course_id
-- JOIN Users u ON tc.teacher_id = u.id
-- WHERE u.username = CURRENT_USER;

-- GO

-- -- 账号信息只能改密码，个人信息不可以改用户名和id号
-- GRANT SELECT, UPDATE(department, introduction) ON V_Teacher_Info TO teacher_role;
-- GRANT SELECT, UPDATE(password) ON V_User_Self TO teacher_role;
-- GRANT SELECT ON V_Teacher_Courses TO teacher_role;
-- GRANT SELECT, INSERT, UPDATE ON V_Teacher_Grades TO teacher_role; 
-- GRANT SELECT ON Students TO teacher_role; 
-- GRANT SELECT ON Courses TO teacher_role; 

-- GO

-- --学生
-- --成绩信息：姓名、学号、学期、课程、成绩、学分
-- CREATE VIEW V_Student_Info AS
-- SELECT s.student_id, s.name, s.gender, s.birth_date
-- FROM Students s JOIN Users u ON s.student_id = u.id
-- WHERE u.username = CURRENT_USER;
-- GO

-- CREATE VIEW V_Student_Grades AS
-- SELECT c.name AS course_name, g.semester, g.score, c.credits,
--        CASE WHEN g.score >= 60 THEN '是' ELSE '否' END AS is_pass
-- FROM Grades g
-- JOIN Courses c ON g.course_id = c.course_id
-- JOIN Users u ON g.student_id = u.id
-- WHERE u.username = CURRENT_USER;
-- GO

-- CREATE VIEW V_Student_SC AS
-- SELECT c.name AS course_name, t.name as teacher_name, sc.semester, c.credits
-- FROM SC sc
-- JOIN Courses c ON sc.course_id = c.course_id
-- JOIN Teachers t ON sc.teacher_id = t.teacher_id
-- JOIN Users u ON sc.student_id = u.id
-- WHERE u.username = CURRENT_USER;
-- GO


-- GRANT SELECT, UPDATE(gender, birth_date) ON V_Student_Info TO student_role;
-- GRANT SELECT, UPDATE(password) ON V_User_Self TO student_role;
-- GRANT SELECT ON V_Student_Grades TO student_role;
-- GRANT SELECT ON V_Student_SC TO student_role;
-- GRANT SELECT ON Courses TO student_role;
-- GRANT SELECT ON TC TO student_role;

