@echo off
chcp 65001 >nul
echo ========================================
echo 学校快递任务代取管理系统 - 启动程序
echo Campus Express Collection Management System
echo ========================================
echo.

echo [1/3] 检查系统状态...
echo.

echo 检查Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到Node.js，请先运行安装程序
    pause
    exit /b 1
)
echo ✓ Node.js 环境正常

echo.
echo 检查后端依赖...
if not exist "backend\node_modules" (
    echo 错误: 后端依赖未安装，请先运行安装程序
    pause
    exit /b 1
)
echo ✓ 后端依赖已安装

echo.
echo 检查数据库连接...
echo 请输入MySQL root密码（如果没有密码请直接按回车）:
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT 1;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo 错误: 数据库连接失败，请检查MySQL服务是否启动
    pause
    exit /b 1
)
echo ✓ 数据库连接正常

echo.
echo [2/3] 启动后端服务...
echo 正在启动服务器，请稍候...
echo.
echo 服务器启动中...
echo 如果看到"服务器运行在端口 3000"表示启动成功
echo 按 Ctrl+C 可以停止服务器
echo.

cd backend
start "快递代取系统 - 后端服务" cmd /k "npm start"
cd ..

echo.
echo [3/3] 等待服务器启动...
echo 等待5秒让服务器完全启动...
timeout /t 5 /nobreak >nul

echo.
echo 正在打开浏览器...
start http://localhost:3000

echo.
echo ========================================
echo 启动完成！
echo ========================================
echo.
echo 📋 系统信息:
echo - 前端地址: http://localhost:3000
echo - API地址: http://localhost:3000/api
echo - 健康检查: http://localhost:3000/api/health
echo.
echo 📝 默认测试账号:
echo - 用户名: 张三, 密码: password123
echo - 用户名: 李四, 密码: password123
echo - 用户名: 王五, 密码: password123
echo - 用户名: 赵六, 密码: password123
echo.
echo 💡 提示:
echo - 浏览器应该已经自动打开
echo - 后端服务在单独的窗口中运行
echo - 关闭后端窗口即可停止服务
echo.
echo ========================================
echo 按任意键退出启动程序
echo ========================================
pause >nul 