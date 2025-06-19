@echo off
chcp 65001 >nul
title Test Script

echo ========================================
echo Express Delivery System - Test
echo ========================================
echo.
echo Current Directory: %CD%
echo Current Time: %date% %time%
echo.
echo Testing basic functionality...
echo.

echo [1/3] Checking Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found
) else (
    echo SUCCESS: Node.js is installed
)

echo.
echo [2/3] Checking project files...
if exist "backend" (
    echo SUCCESS: backend directory exists
) else (
    echo ERROR: backend directory not found
)

if exist "backend\package.json" (
    echo SUCCESS: package.json exists
) else (
    echo ERROR: package.json not found
)

echo.
echo [3/3] Checking MySQL...
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: MySQL not found
) else (
    echo SUCCESS: MySQL is installed
)

echo.
echo ========================================
echo Test completed!
echo ========================================
echo.
echo Press any key to exit...
pause >nul 