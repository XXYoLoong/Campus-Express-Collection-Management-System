@echo off
chcp 65001 >nul
echo ========================================
echo 快递代取系统 - 快速认证修复
echo ========================================
echo.

cd /d "%~dp0"

echo 正在快速修复认证问题...
echo.

echo 1. 检查服务器状态...
tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Node.js服务器正在运行
) else (
    echo ❌ Node.js服务器未运行，正在启动...
    start /B run.bat
    timeout /t 5 /nobreak >nul
)

echo.
echo 2. 运行认证诊断...
node debug_auth.js

echo.
echo ========================================
echo 快速修复步骤：
echo ========================================
echo.
echo 1. 在浏览器中按 F12 打开开发者工具
echo 2. 切换到 Application/应用程序 标签
echo 3. 找到 Local Storage
echo 4. 右键点击并选择"Clear"清除所有数据
echo 5. 刷新页面 (Ctrl+F5)
echo 6. 重新登录
echo.
echo 或者使用页面上的"清除缓存"按钮：
echo 1. 登录后进入"个人中心"
echo 2. 点击"清除缓存"按钮
echo 3. 确认清除并重新登录
echo.
echo ========================================
echo.
echo 按任意键继续...
pause >nul 