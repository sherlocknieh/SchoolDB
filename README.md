# SchoolDB
数据库大作业

## 项目介绍

基于 SQL Server 的学生管理系统;

后台使用 Python 语言:

- 用 Flask 搭建网页服务;
- 用 pyodbc + SQLAlchemy 连接数据库; 

## 运行

0. 用 SQL Server 运行 init 文件夹下的数据库脚本, 创建数据库及表数据;

1. 安装 Python 3.x 环境;

2. 安装依赖:

    pip install -r requirements.txt

3. 修改 modules/config.py 中的数据库连接信息;

4. 运行 APP.py; 浏览器访问 http://localhost:5000;