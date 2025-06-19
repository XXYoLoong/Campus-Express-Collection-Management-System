@echo off
chcp 65001 >nul
title 快递代取系统 - 统一启动器

:main_menu
cls
echo ========================================
echo 学校快递任务代取管理系统 - 统一启动器
echo Campus Express Collection Management System
echo ========================================
echo.
echo 当前目录: %CD%
echo 当前时间: %date% %time%
echo.
echo 请选择操作:
echo.
echo 1. 环境检查
echo 2. 安装依赖
echo 3. 数据库配置
echo 4. 启动系统
echo 5. 一键安装并启动 (推荐)
echo 6. 退出
echo.
echo ========================================
set /p choice=请输入选择 (1-6): 

if "%choice%"=="1" goto check_env
if "%choice%"=="2" goto install_deps
if "%choice%"=="3" goto config_db
if "%choice%"=="4" goto start_system
if "%choice%"=="5" goto auto_setup
if "%choice%"=="6" goto exit_program
echo 无效选择，请重新输入
timeout /t 2 >nul
goto main_menu

:check_env
cls
echo ========================================
echo 环境检查
echo ========================================
echo.

echo [1/3] 检查Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Node.js
    echo 请先安装Node.js: https://nodejs.org/
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ Node.js 已安装

echo.
echo [2/3] 检查项目文件...
if not exist "backend" (
    echo ❌ 错误: 未找到backend目录
    echo 请确保在项目根目录运行此脚本
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ backend目录存在

if not exist "backend\package.json" (
    echo ❌ 错误: 未找到backend/package.json
    echo 请确保项目文件完整
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ package.json存在

echo.
echo [3/3] 检查MySQL...
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 警告: 未找到MySQL命令
    echo 请确保MySQL已安装并在PATH中
    echo 但可以继续其他操作
) else (
    echo ✅ MySQL 已安装
)

echo.
echo ========================================
echo 环境检查完成！
echo ========================================
echo.
echo 按任意键返回主菜单...
pause >nul
goto main_menu

:install_deps
cls
echo ========================================
echo 安装依赖
echo ========================================
echo.

echo 检查后端依赖...
if exist "backend\node_modules" (
    echo ✅ 后端依赖已安装，跳过安装步骤
) else (
    echo 正在安装后端依赖...
    cd backend
    echo 当前目录: %CD%
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ 错误: 依赖安装失败
        echo 请检查网络连接和npm配置
        echo.
        echo 按任意键返回主菜单...
        pause >nul
        cd ..
        goto main_menu
    )
    cd ..
    echo ✅ 后端依赖安装完成
)

echo.
echo ========================================
echo 依赖安装完成！
echo ========================================
echo.
echo 按任意键返回主菜单...
pause >nul
goto main_menu

:config_db
cls
echo ========================================
echo 数据库配置
echo ========================================
echo.

echo 请输入MySQL root密码（如果没有密码请直接按回车）:
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

echo.
echo 正在测试MySQL连接...
if "%mysql_password%"=="" (
    echo 尝试无密码连接...
    mysql -u root -e "SELECT 1;" >nul 2>&1
) else (
    echo 尝试密码连接...
    echo %mysql_password%| mysql -u root -p -e "SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo ❌ 错误: MySQL连接失败
    echo 请检查:
    echo 1. MySQL服务是否启动
    echo 2. 用户名密码是否正确
    echo 3. MySQL是否已安装
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ MySQL连接成功

echo.
echo 检查数据库初始化状态...
if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
)

if %errorlevel% equ 0 (
    echo ✅ 数据库已初始化
) else (
    echo 正在初始化数据库...
    if not exist "database\init.sql" (
        echo ❌ 错误: 未找到database\init.sql文件
        echo 请确保项目文件完整
        echo.
        echo 按任意键返回主菜单...
        pause >nul
        goto main_menu
    )
    
    if "%mysql_password%"=="" (
        echo 执行数据库初始化（无密码）...
        mysql -u root < database/init.sql
    ) else (
        echo 执行数据库初始化（有密码）...
        echo %mysql_password%| mysql -u root -p < database/init.sql
    )

    if %errorlevel% neq 0 (
        echo ❌ 错误: 数据库初始化失败
        echo 请检查:
        echo 1. MySQL权限是否足够
        echo 2. 数据库文件是否完整
        echo 3. 密码是否正确
        echo.
        echo 按任意键返回主菜单...
        pause >nul
        goto main_menu
    )
    echo ✅ 数据库初始化完成
)

echo.
echo ========================================
echo 数据库配置完成！
echo ========================================
echo.
echo 按任意键返回主菜单...
pause >nul
goto main_menu

:start_system
cls
echo ========================================
echo 启动系统
echo ========================================
echo.

echo 检查系统状态...
echo.

echo 检查Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Node.js
    echo 请先运行环境检查
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ Node.js 环境正常

echo.
echo 检查后端依赖...
if not exist "backend\node_modules" (
    echo ❌ 错误: 后端依赖未安装
    echo 请先运行安装依赖
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ 后端依赖已安装

echo.
echo 请输入MySQL root密码（如果没有密码请直接按回车）:
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

echo.
echo 检查数据库连接...
if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT 1;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo ❌ 错误: 数据库连接失败
    echo 请先运行数据库配置
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ 数据库连接正常

echo.
echo 正在启动后端服务...
echo 服务器启动中...
echo 如果看到"服务器运行在端口 3000"表示启动成功
echo 按 Ctrl+C 可以停止服务器
echo.

cd backend
start "快递代取系统 - 后端服务" cmd /k "npm start"
cd ..

echo.
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
echo 系统信息:
echo - 前端地址: http://localhost:3000
echo - API地址: http://localhost:3000/api
echo - 健康检查: http://localhost:3000/api/health
echo.
echo 默认测试账号:
echo - 用户名: 张三, 密码: password123
echo - 用户名: 李四, 密码: password123
echo - 用户名: 王五, 密码: password123
echo - 用户名: 赵六, 密码: password123
echo.
echo 提示:
echo - 浏览器应该已经自动打开
echo - 后端服务在单独的窗口中运行
echo - 关闭后端窗口即可停止服务
echo.
echo 按任意键返回主菜单...
pause >nul
goto main_menu

:auto_setup
cls
echo ========================================
echo 一键安装并启动
echo ========================================
echo.

echo 正在执行自动安装流程...
echo.

echo [1/4] 环境检查...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Node.js
    echo 请先安装Node.js: https://nodejs.org/
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ Node.js 已安装

echo.
echo [2/4] 安装依赖...
if exist "backend\node_modules" (
    echo ✅ 后端依赖已安装，跳过安装步骤
) else (
    echo 正在安装后端依赖...
    cd backend
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ 错误: 依赖安装失败
        echo 请检查网络连接和npm配置
        echo.
        echo 按任意键返回主菜单...
        pause >nul
        cd ..
        goto main_menu
    )
    cd ..
    echo ✅ 后端依赖安装完成
)

echo.
echo [3/4] 数据库配置...
echo 请输入MySQL root密码（如果没有密码请直接按回车）:
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

echo 正在测试MySQL连接...
if "%mysql_password%"=="" (
    mysql -u root -e "SELECT 1;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo ❌ 错误: MySQL连接失败
    echo 请检查MySQL服务是否启动
    echo.
    echo 按任意键返回主菜单...
    pause >nul
    goto main_menu
)
echo ✅ MySQL连接成功

echo 检查数据库初始化状态...
if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo 正在初始化数据库...
    if "%mysql_password%"=="" (
        mysql -u root < database/init.sql
    ) else (
        echo %mysql_password%| mysql -u root -p < database/init.sql
    )

    if %errorlevel% neq 0 (
        echo ❌ 错误: 数据库初始化失败
        echo.
        echo 按任意键返回主菜单...
        pause >nul
        goto main_menu
    )
    echo ✅ 数据库初始化完成
) else (
    echo ✅ 数据库已初始化
)

echo.
echo [4/4] 启动系统...
echo 正在启动后端服务...
cd backend
start "快递代取系统 - 后端服务" cmd /k "npm start"
cd ..

echo 等待5秒让服务器完全启动...
timeout /t 5 /nobreak >nul

echo 正在打开浏览器...
start http://localhost:3000

echo.
echo ========================================
echo 一键安装并启动完成！
echo ========================================
echo.
echo 系统信息:
echo - 前端地址: http://localhost:3000
echo - API地址: http://localhost:3000/api
echo - 健康检查: http://localhost:3000/api/health
echo.
echo 默认测试账号:
echo - 用户名: 张三, 密码: password123
echo - 用户名: 李四, 密码: password123
echo - 用户名: 王五, 密码: password123
echo - 用户名: 赵六, 密码: password123
echo.
echo 提示:
echo - 浏览器应该已经自动打开
echo - 后端服务在单独的窗口中运行
echo - 关闭后端窗口即可停止服务
echo.
echo 按任意键返回主菜单...
pause >nul
goto main_menu

:exit_program
cls
echo ========================================
echo 感谢使用学校快递任务代取管理系统！
echo ========================================
echo.
echo 祝您使用愉快！
echo.
echo 按任意键退出...
pause >nul
exit /b 0 