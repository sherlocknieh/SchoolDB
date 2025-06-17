USE master;
GO
DROP DATABASE SchoolDB;     -- 删除 School 数据库
GO
CREATE DATABASE SchoolDB;   -- 创建 School 数据库
GO
USE SchoolDB;
GO

-- 用户表（统一存储学生、教师、管理员）
-- 使用username当做user使用
CREATE TABLE Users (
    user_id VARCHAR(10) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('student', 'teacher', 'admin'))
);

-- 学生信息表
CREATE TABLE Students (
    student_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(10),
    birth_date DATE,
    FOREIGN KEY (student_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 教师信息表
CREATE TABLE Teachers (
    teacher_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    introduction TEXT,
    FOREIGN KEY (teacher_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 课程信息表
CREATE TABLE Courses (
    course_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT, 
    credits INT NOT NULL
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
    PRIMARY KEY (student_id, course_id, semester)
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


-- 创建初始数据
INSERT INTO Users (user_id, username, [password], role)
VALUES ('a0001', 'admin',   '123456', 'admin'  ),
       ('s0001', 'student1', '123456', 'student'),
       ('s0002', 'student2', '123456', 'student'),
       ('t0001', 'teacher1', '123456', 'teacher'),
       ('t0002', 'teacher2', '123456', 'teacher');

INSERT INTO Students (student_id, name, gender, birth_date)
VALUES ('s0001', '学生1', '男', '2000-01-01'),
       ('s0002', '学生2', '女', '2000-02-02');

INSERT INTO Teachers (teacher_id, name, department, introduction)
VALUES ('t0001', '教师1', '数学学院', NULL),
       ('t0002', '教师2', '计算机学院', NULL);


INSERT INTO Courses (course_id, name, description, credits)
VALUES ('c0001', '微积分', '微积分课程', 4),
       ('c0002', '数据结构', '数据结构课程', 3),
       ('c0003', '操作系统', '操作系统课程', 3);


INSERT INTO TC (teacher_id, course_id, semester)
VALUES ('t0001', 'c0001', '2022秋'),
       ('t0001', 'c0002', '2023春'),
       ('t0002', 'c0002', '2023春'),
       ('t0002', 'c0003', '2023秋');


INSERT INTO SC (student_id, teacher_id, course_id, semester)
VALUES ('s0001', 't0001', 'c0001', '2022秋'),
       ('s0001', 't0001', 'c0002', '2023春'),
       ('s0001', 't0002', 'c0003', '2023秋'),
       ('s0002', 't0001', 'c0001', '2022秋'),
       ('s0002', 't0002', 'c0002', '2023春'),
       ('s0002', 't0002', 'c0003', '2023秋');
       
INSERT INTO Grades (student_id, course_id, semester, score)
VALUES ('s0001', 'c0001', '2022秋', 80),
       ('s0001', 'c0002', '2023春', 90),
       ('s0001', 'c0003', '2023秋', 85),
       ('s0002', 'c0001', '2022秋', 70),
       ('s0002', 'c0002', '2023春', 80),
       ('s0002', 'c0003', '2023秋', 90);