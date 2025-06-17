
if __name__ == '__main__':
    from config import create_connection
else:
    from .config import create_connection



""" 教师用户操作 API
接收来自网页的命令
解析命令并执行相应的操作
返回结果
"""


def teacher_action(cmd):
    """
    教师命令解析器
    """