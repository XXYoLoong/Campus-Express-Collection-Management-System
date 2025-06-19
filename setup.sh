#!/bin/bash

echo "========================================"
echo "学校快递任务代取管理系统 - 安装脚本"
echo "Campus Express Collection Management System"
echo "========================================"
echo

echo "正在检查安装状态..."
echo

echo "[1/4] 检查Node.js环境..."
if ! command -v node &> /dev/null; then
    echo "错误: 未找到Node.js，请先安装Node.js"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi
echo "✓ Node.js 已安装"

echo
echo "[2/4] 检查后端依赖..."
if [ -d "backend/node_modules" ]; then
    echo "✓ 后端依赖已安装，跳过安装步骤"
else
    echo "正在安装后端依赖..."
    cd backend
    npm install
    if [ $? -ne 0 ]; then
        echo "错误: 依赖安装失败"
        exit 1
    fi
    cd ..
    echo "✓ 后端依赖安装完成"
fi

echo
echo "[3/4] 检查MySQL连接..."
echo "请输入MySQL root密码（如果没有密码请直接按回车）:"
read -s mysql_password

echo "正在测试MySQL连接..."
if [ -z "$mysql_password" ]; then
    mysql -u root -e "SELECT 1;" > /dev/null 2>&1
else
    echo "$mysql_password" | mysql -u root -p -e "SELECT 1;" > /dev/null 2>&1
fi

if [ $? -ne 0 ]; then
    echo "错误: MySQL连接失败，请检查:"
    echo "1. MySQL服务是否启动"
    echo "2. 用户名密码是否正确"
    echo "3. MySQL是否已安装"
    exit 1
fi
echo "✓ MySQL连接成功"

echo
echo "[4/4] 检查数据库初始化状态..."
if [ -z "$mysql_password" ]; then
    mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" > /dev/null 2>&1
else
    echo "$mysql_password" | mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
    echo "✓ 数据库已初始化，跳过初始化步骤"
else
    echo "正在初始化数据库..."
    if [ -z "$mysql_password" ]; then
        mysql -u root < database/init.sql
    else
        echo "$mysql_password" | mysql -u root -p < database/init.sql
    fi

    if [ $? -ne 0 ]; then
        echo "错误: 数据库初始化失败"
        exit 1
    fi
    echo "✓ 数据库初始化完成"
fi

echo
echo "========================================"
echo "安装检查完成！"
echo "========================================"
echo
echo "📋 系统状态:"
echo "✓ Node.js 环境正常"
echo "✓ 后端依赖已安装"
echo "✓ MySQL 连接正常"
echo "✓ 数据库已初始化"
echo
echo "🚀 下一步操作:"
echo
echo "1. 启动服务:"
echo "   npm start"
echo
echo "2. 访问系统:"
echo "   前端界面: http://localhost:3000"
echo "   API接口: http://localhost:3000/api"
echo "   健康检查: http://localhost:3000/api/health"
echo
echo "3. 开发模式（自动重启）:"
echo "   npm run dev"
echo
echo "📝 默认测试账号:"
echo "- 用户名: 张三, 密码: password123"
echo "- 用户名: 李四, 密码: password123"
echo "- 用户名: 王五, 密码: password123"
echo "- 用户名: 赵六, 密码: password123"
echo
echo "🔧 常用命令:"
echo "- 查看任务列表: 访问 http://localhost:3000"
echo "- 发布任务: 登录后点击'发布任务'"
echo "- 接取任务: 在任务列表中点击'接单'"
echo "- 管理任务: 点击'我的任务'"
echo "- 查看评价: 点击'评价管理'"
echo
echo "📚 数据库操作:"
echo "- 连接数据库: mysql -u root -p express_delivery_system"
echo "- 查看用户: SELECT * FROM User;"
echo "- 查看任务: SELECT * FROM DeliveryTask;"
echo "- 查看评价: SELECT * FROM Rating;"
echo
echo "❓ 遇到问题:"
echo "1. 端口被占用: 修改 backend/server.js 中的端口号"
echo "2. 数据库连接失败: 检查MySQL服务是否启动"
echo "3. 依赖安装失败: 删除 backend/node_modules 后重新安装"
echo
echo "💡 提示:"
echo "- 首次使用建议先注册新账号"
echo "- 可以发布测试任务来熟悉系统功能"
echo "- 系统支持任务发布、接单、完成、评价等完整流程"
echo
echo "========================================"
echo "选择操作:"
echo "1. 立即启动系统 (推荐)"
echo "2. 退出安装程序"
echo "========================================"

while true; do
    read -p "请输入选择 (1 或 2): " user_choice
    case $user_choice in
        1)
            echo
            echo "正在启动系统..."
            ./start.sh
            exit 0
            ;;
        2)
            echo
            echo "感谢使用学校快递任务代取管理系统！"
            echo "如需启动系统，请运行 ./start.sh"
            echo "祝您使用愉快！"
            exit 0
            ;;
        *)
            echo "无效选择，请输入 1 或 2"
            ;;
    esac
done 