@echo off
chcp 65001 >nul
echo ========================================
echo 快递代取系统 - 认证问题修复工具
echo ========================================
echo.

cd /d "%~dp0"

echo 正在诊断认证问题...
echo.

echo 1. 运行认证诊断...
node debug_auth.js

echo.
echo ========================================
echo 快速修复步骤：
echo ========================================
echo.
echo 1. 清除浏览器缓存：
echo    - 按 F12 打开开发者工具
echo    - 右键点击刷新按钮，选择"清空缓存并硬性重新加载"
echo    - 或者按 Ctrl+Shift+R
echo.
echo 2. 清除localStorage：
echo    - 按 F12 打开开发者工具
echo    - 切换到 Application/应用程序 标签
echo    - 找到 Local Storage
echo    - 删除所有项目
echo.
echo 3. 重新登录：
echo    - 刷新页面
echo    - 重新注册或登录
echo.
echo 4. 如果问题持续：
echo    - 重启服务器（运行 run.bat）
echo    - 检查MySQL服务是否正常运行
echo.
echo ========================================
echo.
echo 按任意键继续...
pause >nul 