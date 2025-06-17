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
    FOREIGN KEY (teacher_id, course_id, semester) REFERENCES TC(teacher_id, course_id, semester) ON DELETE CASCADE,
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
VALUES (1, 'admin', '123456', 'admin');