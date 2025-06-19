#!/bin/bash

# 设置中文编码
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 标题
echo -e "${BLUE}========================================"
echo "学校快递任务代取管理系统 - 统一启动器"
echo "Campus Express Collection Management System"
echo -e "========================================${NC}"
echo
echo "当前目录: $(pwd)"
echo "当前时间: $(date)"
echo

# 主菜单函数
show_main_menu() {
    echo "请选择操作:"
    echo
    echo "1. 环境检查 (推荐首次使用)"
    echo "2. 安装依赖"
    echo "3. 数据库初始化"
    echo "4. 启动系统"
    echo "5. 一键完整安装并启动"
    echo "6. 退出"
    echo
    echo -e "${BLUE}========================================${NC}"
    read -p "请输入选择 (1-6): " choice
}

# 环境检查函数
check_environment() {
    echo -e "${BLUE}========================================"
    echo "环境检查"
    echo -e "========================================${NC}"
    echo

    echo "[1/3] 检查Node.js环境..."
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✅ Node.js 已安装${NC}"
    else
        echo -e "${RED}❌ 错误: 未找到Node.js${NC}"
        echo "请先安装Node.js: https://nodejs.org/"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo
    echo "[2/3] 检查项目文件..."
    if [ ! -d "backend" ]; then
        echo -e "${RED}❌ 错误: 未找到backend目录${NC}"
        echo "请确保在项目根目录运行此脚本"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ backend目录存在${NC}"

    if [ ! -f "backend/package.json" ]; then
        echo -e "${RED}❌ 错误: 未找到backend/package.json${NC}"
        echo "请确保项目文件完整"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ package.json存在${NC}"

    echo
    echo "[3/3] 检查MySQL..."
    if command -v mysql &> /dev/null; then
        echo -e "${GREEN}✅ MySQL 已安装${NC}"
    else
        echo -e "${RED}❌ 错误: 未找到MySQL${NC}"
        echo "请先安装MySQL: https://dev.mysql.com/downloads/"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo
    echo -e "${BLUE}========================================"
    echo "环境检查完成！所有组件正常"
    echo -e "========================================${NC}"
    echo
    read -p "按回车键返回主菜单..."
}

# 安装依赖函数
install_dependencies() {
    echo -e "${BLUE}========================================"
    echo "安装依赖"
    echo -e "========================================${NC}"
    echo

    if [ -d "backend/node_modules" ]; then
        echo -e "${GREEN}✅ 后端依赖已安装，跳过安装步骤${NC}"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo "正在安装后端依赖..."
    cd backend
    if npm install; then
        cd ..
        echo -e "${GREEN}✅ 后端依赖安装完成${NC}"
    else
        cd ..
        echo -e "${RED}❌ 错误: 依赖安装失败${NC}"
        echo "请检查网络连接和npm配置"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo
    read -p "按回车键返回主菜单..."
}

# 数据库初始化函数
init_database() {
    echo -e "${BLUE}========================================"
    echo "数据库初始化"
    echo -e "========================================${NC}"
    echo

    echo -n "请输入MySQL root密码（如果没有密码请直接按回车）: "
    read -s mysql_password
    echo

    echo
    echo "正在测试MySQL连接..."
    if [ -z "$mysql_password" ]; then
        mysql -u root -e "SELECT 1;" &> /dev/null
    else
        echo "$mysql_password" | mysql -u root -p -e "SELECT 1;" &> /dev/null
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 错误: MySQL连接失败${NC}"
        echo "请检查:"
        echo "1. MySQL服务是否启动"
        echo "2. 用户名密码是否正确"
        echo "3. MySQL是否已安装"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ MySQL连接成功${NC}"

    echo
    echo "检查数据库是否已初始化..."
    if [ -z "$mysql_password" ]; then
        mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" &> /dev/null
    else
        echo "$mysql_password" | mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" &> /dev/null
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库已初始化，跳过初始化步骤${NC}"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo "正在初始化数据库..."
    if [ ! -f "database/init.sql" ]; then
        echo -e "${RED}❌ 错误: 未找到database/init.sql文件${NC}"
        echo "请确保项目文件完整"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    if [ -z "$mysql_password" ]; then
        mysql -u root < database/init.sql
    else
        echo "$mysql_password" | mysql -u root -p < database/init.sql
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 错误: 数据库初始化失败${NC}"
        echo "请检查:"
        echo "1. MySQL权限是否足够"
        echo "2. 数据库文件是否完整"
        echo "3. 密码是否正确"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo -e "${GREEN}✅ 数据库初始化完成${NC}"
    echo
    read -p "按回车键返回主菜单..."
}

# 启动系统函数
start_system() {
    echo -e "${BLUE}========================================"
    echo "启动系统"
    echo -e "========================================${NC}"
    echo

    echo "检查系统状态..."
    echo

    if [ ! -d "backend/node_modules" ]; then
        echo -e "${RED}❌ 错误: 后端依赖未安装${NC}"
        echo "请先选择"安装依赖""
        echo
        read -p "按回车键返回主菜单..."
        return
    fi

    echo -n "请输入MySQL root密码（如果没有密码请直接按回车）: "
    read -s mysql_password
    echo

    echo
    echo "正在配置数据库连接..."
    echo

    echo "备份原配置文件..."
    cp backend/config/database.js backend/config/database.js.backup

    echo "创建临时配置文件..."
    cat > backend/config/database.js << EOF
const mysql = require('mysql2/promise');

// 数据库配置
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '$mysql_password',
    database: process.env.DB_NAME || 'express_delivery_system',
    charset: 'utf8mb4',
    timezone: '+08:00'
};

// 创建连接池
const pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 测试数据库连接
async function testConnection() {
    try {
        const connection = await pool.getConnection();
        console.log('数据库连接成功！');
        connection.release();
    } catch (error) {
        console.error('数据库连接失败：', error.message);
        console.log('\n解决方案：');
        console.log('1. 确保MySQL服务已启动');
        console.log('2. 检查用户名和密码是否正确');
        console.log('3. 设置环境变量 DB_PASSWORD=你的密码');
        console.log('4. 或者修改此文件中的password字段');
        console.log('\n示例：');
        console.log('   password: process.env.DB_PASSWORD || "your_password_here"');
        process.exit(1);
    }
}

module.exports = {
    pool,
    testConnection
};
EOF

    echo -e "${GREEN}✅ 数据库配置完成${NC}"
    echo
    echo "正在启动后端服务..."
    echo

    cd backend
    npm start &
    cd ..

    echo
    echo "等待5秒让服务器启动..."
    sleep 5

    echo
    echo "正在打开浏览器..."
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3000
    elif command -v open &> /dev/null; then
        open http://localhost:3000
    else
        echo "请手动打开浏览器访问: http://localhost:3000"
    fi

    echo
    echo -e "${BLUE}========================================"
    echo "系统启动完成！"
    echo -e "========================================${NC}"
    echo
    echo "系统信息:"
    echo "- 前端地址: http://localhost:3000"
    echo "- API地址: http://localhost:3000/api"
    echo "- 健康检查: http://localhost:3000/api/health"
    echo
    echo "默认测试账号:"
    echo "- 用户名: 张三, 密码: password123"
    echo "- 用户名: 李四, 密码: password123"
    echo "- 用户名: 王五, 密码: password123"
    echo "- 用户名: 赵六, 密码: password123"
    echo
    echo "提示:"
    echo "- 浏览器应该已经自动打开"
    echo "- 后端服务在后台运行"
    echo "- 使用 Ctrl+C 停止服务"
    echo
    read -p "按回车键返回主菜单..."
}

# 一键完整安装并启动函数
full_setup() {
    echo -e "${BLUE}========================================"
    echo "一键完整安装并启动"
    echo -e "========================================${NC}"
    echo

    echo "此选项将自动执行以下步骤:"
    echo "1. 环境检查"
    echo "2. 安装依赖"
    echo "3. 数据库初始化"
    echo "4. 启动系统"
    echo
    read -p "是否继续？(y/n): " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    echo
    echo "开始执行完整安装..."
    echo

    echo "[1/4] 环境检查..."
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ 错误: 未找到Node.js${NC}"
        echo "请先安装Node.js: https://nodejs.org/"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ Node.js 已安装${NC}"

    if [ ! -f "backend/package.json" ]; then
        echo -e "${RED}❌ 错误: 未找到backend/package.json${NC}"
        echo "请确保项目文件完整"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ 项目文件完整${NC}"

    echo
    echo "[2/4] 安装依赖..."
    if [ ! -d "backend/node_modules" ]; then
        cd backend
        if npm install; then
            cd ..
            echo -e "${GREEN}✅ 依赖安装完成${NC}"
        else
            cd ..
            echo -e "${RED}❌ 错误: 依赖安装失败${NC}"
            echo
            read -p "按回车键返回主菜单..."
            return
        fi
    else
        echo -e "${GREEN}✅ 依赖已安装，跳过${NC}"
    fi

    echo
    echo "[3/4] 数据库初始化..."
    echo -n "请输入MySQL root密码（如果没有密码请直接按回车）: "
    read -s mysql_password
    echo

    if [ -z "$mysql_password" ]; then
        mysql -u root -e "SELECT 1;" &> /dev/null
    else
        echo "$mysql_password" | mysql -u root -p -e "SELECT 1;" &> /dev/null
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 错误: MySQL连接失败${NC}"
        echo
        read -p "按回车键返回主菜单..."
        return
    fi
    echo -e "${GREEN}✅ MySQL连接成功${NC}"

    if [ -z "$mysql_password" ]; then
        mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" &> /dev/null
    else
        echo "$mysql_password" | mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" &> /dev/null
    fi

    if [ $? -ne 0 ]; then
        if [ -z "$mysql_password" ]; then
            mysql -u root < database/init.sql
        else
            echo "$mysql_password" | mysql -u root -p < database/init.sql
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ 错误: 数据库初始化失败${NC}"
            echo
            read -p "按回车键返回主菜单..."
            return
        fi
        echo -e "${GREEN}✅ 数据库初始化完成${NC}"
    else
        echo -e "${GREEN}✅ 数据库已初始化，跳过${NC}"
    fi

    echo
    echo "[4/4] 启动系统..."
    echo "正在配置数据库连接..."

    cp backend/config/database.js backend/config/database.js.backup

    cat > backend/config/database.js << EOF
const mysql = require('mysql2/promise');

// 数据库配置
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '$mysql_password',
    database: process.env.DB_NAME || 'express_delivery_system',
    charset: 'utf8mb4',
    timezone: '+08:00'
};

// 创建连接池
const pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 测试数据库连接
async function testConnection() {
    try {
        const connection = await pool.getConnection();
        console.log('数据库连接成功！');
        connection.release();
    } catch (error) {
        console.error('数据库连接失败：', error.message);
        console.log('\n解决方案：');
        console.log('1. 确保MySQL服务已启动');
        console.log('2. 检查用户名和密码是否正确');
        console.log('3. 设置环境变量 DB_PASSWORD=你的密码');
        console.log('4. 或者修改此文件中的password字段');
        console.log('\n示例：');
        console.log('   password: process.env.DB_PASSWORD || "your_password_here"');
        process.exit(1);
    }
}

module.exports = {
    pool,
    testConnection
};
EOF

    cd backend
    npm start &
    cd ..

    echo
    echo "等待5秒让服务器启动..."
    sleep 5

    echo
    echo "正在打开浏览器..."
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3000
    elif command -v open &> /dev/null; then
        open http://localhost:3000
    else
        echo "请手动打开浏览器访问: http://localhost:3000"
    fi

    echo
    echo -e "${BLUE}========================================"
    echo "完整安装并启动完成！"
    echo -e "========================================${NC}"
    echo
    echo "系统信息:"
    echo "- 前端地址: http://localhost:3000"
    echo "- API地址: http://localhost:3000/api"
    echo "- 健康检查: http://localhost:3000/api/health"
    echo
    echo "默认测试账号:"
    echo "- 用户名: 张三, 密码: password123"
    echo "- 用户名: 李四, 密码: password123"
    echo "- 用户名: 王五, 密码: password123"
    echo "- 用户名: 赵六, 密码: password123"
    echo
    echo "提示:"
    echo "- 浏览器应该已经自动打开"
    echo "- 后端服务在后台运行"
    echo "- 使用 Ctrl+C 停止服务"
    echo
    read -p "按回车键返回主菜单..."
}

# 退出函数
exit_program() {
    echo -e "${BLUE}========================================"
    echo "感谢使用学校快递任务代取管理系统！"
    echo -e "========================================${NC}"
    echo
    echo "祝您使用愉快！"
    echo
    read -p "按回车键退出..."
    exit 0
}

# 主循环
while true; do
    show_main_menu
    
    case $choice in
        1)
            check_environment
            ;;
        2)
            install_dependencies
            ;;
        3)
            init_database
            ;;
        4)
            start_system
            ;;
        5)
            full_setup
            ;;
        6)
            exit_program
            ;;
        *)
            echo "无效选择，请重新输入"
            sleep 2
            ;;
    esac
done 