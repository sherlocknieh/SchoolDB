USE master;
GO
DROP DATABASE School;     -- 删除 School 数据库
GO
CREATE DATABASE School;   -- 创建 School 数据库
GO
USE School;
GO

-- 用户表（统一存储学生、教师、管理员）
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
    FOREIGN KEY (student_id) REFERENCES Users(id)
);

-- 教师信息表
CREATE TABLE Teachers (
    teacher_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    FOREIGN KEY (teacher_id) REFERENCES Users(id)
);

-- 课程信息表
CREATE TABLE Courses (
    course_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    credits INT NOT NULL
);

-- 成绩表
CREATE TABLE Grades (
    grade_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id VARCHAR(10),
    course_id VARCHAR(10),
    score INT CHECK (score BETWEEN 0 AND 100),
    semester VARCHAR(20),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);
