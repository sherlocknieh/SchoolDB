
# 导入数据库连接模块
if __name__ == '__main__':
    from config import create_connection  # 直接运行本文件时，从当前目录导入模块
else:
    from .config import create_connection # 从 APP.py 运行时，从当前目录的父目录导入模块



""" 学生用户操作 API
接收来自网页的命令
解析命令并执行相应的操作
返回结果
"""


def student_action(cmd=None):
    """
    student 命令解析器
    """

    # 手写的测试数据，用于模拟查询结果
    test_result = [
        {
        "id": 1,
        "name": "语文",
        "score": 90
        },
        {
        "id": 2,
        "name": "数学",
        "score": 80
        },
        {
        "id": 3,
        "name": "英语",
        "score": 70
        }
    ]
    return test_result