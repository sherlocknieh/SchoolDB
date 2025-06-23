# SchoolDB
数据库作业

## 项目介绍

基于 SQL Server 的学生成绩管理系统;

后台使用 Python 语言:

- 用 Flask 搭建网页服务;
- 用 pyodbc 连接数据库;

## 运行

1. 连接 SQL Server 并运行 init 目录下的脚本, 创建数据库;

2. 安装 Python3, 并安装依赖:

    > pip install -r requirements.txt

3. 修改 modules/config.py 中的数据库连接信息;

4. 运行 APP.py; 浏览器访问 http://localhost:5000;