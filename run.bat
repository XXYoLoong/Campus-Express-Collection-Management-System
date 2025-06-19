@echo off
chcp 65001 >nul
title Express Delivery System - Launcher

:main_menu
cls
echo ========================================
echo Express Delivery Management System
echo ========================================
echo.
echo Current Directory: %CD%
echo Current Time: %date% %time%
echo.
echo Please select an operation:
echo.
echo 1. Environment Check (Recommended for first use)
echo 2. Install Dependencies
echo 3. Initialize Database
echo 4. Start System
echo 5. Full Setup and Start
echo 6. Exit
echo.
echo ========================================
set /p choice=Enter your choice (1-6): 

if "%choice%"=="1" goto check_env
if "%choice%"=="2" goto install_deps
if "%choice%"=="3" goto init_db
if "%choice%"=="4" goto start_system
if "%choice%"=="5" goto full_setup
if "%choice%"=="6" goto exit_program
echo Invalid choice, please try again
timeout /t 2 >nul
goto main_menu

:check_env
cls
echo ========================================
echo Environment Check
echo ========================================
echo.

echo [1/3] Checking Node.js environment...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found
    echo Please install Node.js: https://nodejs.org/
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: Node.js is installed

echo.
echo [2/3] Checking project files...
if not exist "backend" (
    echo ERROR: backend directory not found
    echo Please ensure you are running this script from the project root
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: backend directory exists

if not exist "backend\package.json" (
    echo ERROR: backend/package.json not found
    echo Please ensure project files are complete
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: package.json exists

echo.
echo [3/3] Checking MySQL...
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: MySQL not found
    echo Please install MySQL: https://dev.mysql.com/downloads/
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: MySQL is installed

echo.
echo ========================================
echo Environment check completed! All components are normal
echo ========================================
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:install_deps
cls
echo ========================================
echo Install Dependencies
echo ========================================
echo.

if exist "backend\node_modules" (
    echo SUCCESS: Backend dependencies already installed, skipping
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)

echo Installing backend dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Dependency installation failed
    echo Please check network connection and npm configuration
    echo.
    echo Press any key to return to main menu...
    pause >nul
    cd ..
    goto main_menu
)
cd ..
echo SUCCESS: Backend dependencies installed
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:init_db
cls
echo ========================================
echo Initialize Database
echo ========================================
echo.

echo Please enter MySQL root password (press Enter if no password):
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

echo.
echo Testing MySQL connection...
if "%mysql_password%"=="" (
    mysql -u root -e "SELECT 1;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo ERROR: MySQL connection failed
    echo Please check:
    echo 1. MySQL service is running
    echo 2. Username and password are correct
    echo 3. MySQL is installed
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: MySQL connection successful

echo.
echo Checking if database is already initialized...
if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
)

if %errorlevel% equ 0 (
    echo SUCCESS: Database already initialized, skipping
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)

echo Initializing database...
if not exist "database\init.sql" (
    echo ERROR: database\init.sql file not found
    echo Please ensure project files are complete
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)

if "%mysql_password%"=="" (
    mysql -u root < database/init.sql
) else (
    echo %mysql_password%| mysql -u root -p < database/init.sql
)

if %errorlevel% neq 0 (
    echo ERROR: Database initialization failed
    echo Please check:
    echo 1. MySQL permissions are sufficient
    echo 2. Database files are complete
    echo 3. Password is correct
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)

echo SUCCESS: Database initialization completed
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:start_system
cls
echo ========================================
echo Start System
echo ========================================
echo.

echo Checking system status...
echo.

if not exist "backend\node_modules" (
    echo ERROR: Backend dependencies not installed
    echo Please select "Install Dependencies" first
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)

echo IMPORTANT: Database password will be requested during startup
echo If connection fails, you can enter password interactively
echo Browser will open automatically after successful connection
echo.
echo Please enter MySQL root password (press Enter if no password):
echo Note: This is for initial configuration only
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

echo.
echo Configuring database connection...
echo.

echo Backing up original configuration file...
copy "backend\config\database.js" "backend\config\database.js.backup" >nul

echo Creating temporary configuration file...
(
echo const mysql = require^('mysql2/promise'^);
echo const readline = require^('readline'^);
echo.
echo // Create readline interface
echo const rl = readline.createInterface^({
echo     input: process.stdin,
echo     output: process.stdout
echo });
echo.
echo // Database configuration
echo let dbConfig = {
echo     host: process.env.DB_HOST ^|^| 'localhost',
echo     user: process.env.DB_USER ^|^| 'root',
echo     password: process.env.DB_PASSWORD ^|^| '%mysql_password%',
echo     database: process.env.DB_NAME ^|^| 'express_delivery_system',
echo     charset: 'utf8mb4',
echo     timezone: '+08:00'
echo };
echo.
echo // Create connection pool
echo let pool = mysql.createPool^({
echo     ...dbConfig,
echo     waitForConnections: true,
echo     connectionLimit: 10,
echo     queueLimit: 0
echo });
echo.
echo // Update database configuration
echo function updateDbConfig^(newPassword^) {
echo     dbConfig.password = newPassword;
echo     pool = mysql.createPool^({
echo         ...dbConfig,
echo         waitForConnections: true,
echo         connectionLimit: 10,
echo         queueLimit: 0
echo     });
echo }
echo.
echo // Interactive password input
echo function promptForPassword^(^) {
echo     return new Promise^(^(resolve^) =^> {
echo         console.log^('\nDatabase connection failed, please enter MySQL root password:'^);
echo         console.log^('(Press Enter if no password)'^);
echo         
echo         rl.question^('MySQL Password: ', ^(password^) =^> {
echo             resolve^(password^);
echo         }^);
echo     }^);
echo }
echo.
echo // Test database connection
echo async function testConnection^(^) {
echo     try {
echo         const connection = await pool.getConnection^(^);
echo         console.log^('Database connection successful!'^);
echo         connection.release^(^);
echo         rl.close^(^);
echo     } catch ^(error^) {
echo         console.error^('Database connection failed:', error.message^);
echo         
echo         // If password error, try interactive input
echo         if ^(error.message.includes^('Access denied'^) ^|^| error.message.includes^('using password: NO'^)^) {
echo             console.log^('\nTrying interactive password input...'^);
echo             
echo             try {
echo                 const password = await promptForPassword^(^);
echo                 updateDbConfig^(password^);
echo                 
echo                 // Retry connection
echo                 const newConnection = await pool.getConnection^(^);
echo                 console.log^('Database connection successful!'^);
echo                 newConnection.release^(^);
echo                 rl.close^(^);
echo             } catch ^(retryError^) {
echo                 console.error^('Still failed after password input:', retryError.message^);
echo                 console.log^('\nSolutions:'^);
echo                 console.log^('1. Ensure MySQL service is running'^);
echo                 console.log^('2. Check username and password'^);
echo                 console.log^('3. Set environment variable DB_PASSWORD=your_password'^);
echo                 console.log^('4. Or modify password field in this file'^);
echo                 console.log^('\nExample:'^);
echo                 console.log^('   password: process.env.DB_PASSWORD ^|^| "your_password_here"'^);
echo                 console.log^('\nQuick fix:'^);
echo                 console.log^('   Run run.bat script to auto-configure password'^);
echo                 rl.close^(^);
echo                 process.exit^(1^);
echo             }
echo         } else {
echo             console.log^('\nSolutions:'^);
echo             console.log^('1. Ensure MySQL service is running'^);
echo             console.log^('2. Check username and password'^);
echo             console.log^('3. Set environment variable DB_PASSWORD=your_password'^);
echo             console.log^('4. Or modify password field in this file'^);
echo             console.log^('\nExample:'^);
echo             console.log^('   password: process.env.DB_PASSWORD ^|^| "your_password_here"'^);
echo             console.log^('\nQuick fix:'^);
echo             console.log^('   Run run.bat script to auto-configure password'^);
echo             rl.close^(^);
echo             process.exit^(1^);
echo         }
echo     }
echo }
echo.
echo module.exports = {
echo     pool,
echo     testConnection,
echo     updateDbConfig
echo };
) > "backend\config\database.js"

echo SUCCESS: Database configuration completed
echo.
echo Starting backend service...
echo.

cd backend
start "Express Delivery System - Backend" cmd /k "npm start"
cd ..

echo.
echo ========================================
echo System startup completed!
echo ========================================
echo.
echo System Information:
echo - Frontend: http://localhost:3000
echo - API: http://localhost:3000/api
echo - Health Check: http://localhost:3000/api/health
echo.
echo Default Test Accounts:
echo - Username: zhangsan, Password: password123
echo - Username: lisi, Password: password123
echo - Username: wangwu, Password: password123
echo - Username: zhaoliu, Password: password123
echo.
echo Tips:
echo - Backend service runs in a separate window
echo - Close backend window to stop service
echo - If database connection fails, password will be requested interactively
echo - Browser will open automatically after successful database connection
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:full_setup
cls
echo ========================================
echo Full Setup and Start
echo ========================================
echo.

echo This option will automatically execute the following steps:
echo 1. Environment check
echo 2. Install dependencies
echo 3. Initialize database
echo 4. Start system
echo.
set /p confirm=Continue? (y/n): 

if /i not "%confirm%"=="y" goto main_menu

echo.
echo Starting full installation...
echo.

echo [1/4] Environment check...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found
    echo Please install Node.js: https://nodejs.org/
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: Node.js is installed

if not exist "backend\package.json" (
    echo ERROR: backend/package.json not found
    echo Please ensure project files are complete
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: Project files are complete

echo.
echo [2/4] Install dependencies...
if not exist "backend\node_modules" (
    cd backend
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Dependency installation failed
        echo.
        echo Press any key to return to main menu...
        pause >nul
        cd ..
        goto main_menu
    )
    cd ..
    echo SUCCESS: Dependencies installed
) else (
    echo SUCCESS: Dependencies already installed, skipping
)

echo.
echo [3/4] Initialize database...
echo Please enter MySQL root password (press Enter if no password):
powershell -Command "$password = Read-Host -AsSecureString -Prompt 'MySQL Password'; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password); $mysql_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); Set-Content -Path 'temp_password.txt' -Value $mysql_password -NoNewline"
set /p mysql_password=<temp_password.txt
del temp_password.txt

if "%mysql_password%"=="" (
    mysql -u root -e "SELECT 1;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "SELECT 1;" >nul 2>&1
)

if %errorlevel% neq 0 (
    echo ERROR: MySQL connection failed
    echo.
    echo Press any key to return to main menu...
    pause >nul
    goto main_menu
)
echo SUCCESS: MySQL connection successful

if "%mysql_password%"=="" (
    mysql -u root -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
) else (
    echo %mysql_password%| mysql -u root -p -e "USE express_delivery_system; SELECT COUNT(*) FROM User;" >nul 2>&1
)

if %errorlevel% neq 0 (
    if "%mysql_password%"=="" (
        mysql -u root < database/init.sql
    ) else (
        echo %mysql_password%| mysql -u root -p < database/init.sql
    )
    
    if %errorlevel% neq 0 (
        echo ERROR: Database initialization failed
        echo.
        echo Press any key to return to main menu...
        pause >nul
        goto main_menu
    )
    echo SUCCESS: Database initialization completed
) else (
    echo SUCCESS: Database already initialized, skipping
)

echo.
echo [4/4] Start system...
echo Configuring database connection...

copy "backend\config\database.js" "backend\config\database.js.backup" >nul

(
echo const mysql = require^('mysql2/promise'^);
echo const readline = require^('readline'^);
echo.
echo // Create readline interface
echo const rl = readline.createInterface^({
echo     input: process.stdin,
echo     output: process.stdout
echo });
echo.
echo // Database configuration
echo let dbConfig = {
echo     host: process.env.DB_HOST ^|^| 'localhost',
echo     user: process.env.DB_USER ^|^| 'root',
echo     password: process.env.DB_PASSWORD ^|^| '%mysql_password%',
echo     database: process.env.DB_NAME ^|^| 'express_delivery_system',
echo     charset: 'utf8mb4',
echo     timezone: '+08:00'
echo };
echo.
echo // Create connection pool
echo let pool = mysql.createPool^({
echo     ...dbConfig,
echo     waitForConnections: true,
echo     connectionLimit: 10,
echo     queueLimit: 0
echo });
echo.
echo // Update database configuration
echo function updateDbConfig^(newPassword^) {
echo     dbConfig.password = newPassword;
echo     pool = mysql.createPool^({
echo         ...dbConfig,
echo         waitForConnections: true,
echo         connectionLimit: 10,
echo         queueLimit: 0
echo     });
echo }
echo.
echo // Interactive password input
echo function promptForPassword^(^) {
echo     return new Promise^(^(resolve^) =^> {
echo         console.log^('\nDatabase connection failed, please enter MySQL root password:'^);
echo         console.log^('(Press Enter if no password)'^);
echo         
echo         rl.question^('MySQL Password: ', ^(password^) =^> {
echo             resolve^(password^);
echo         }^);
echo     }^);
echo }
echo.
echo // Test database connection
echo async function testConnection^(^) {
echo     try {
echo         const connection = await pool.getConnection^(^);
echo         console.log^('Database connection successful!'^);
echo         connection.release^(^);
echo         rl.close^(^);
echo     } catch ^(error^) {
echo         console.error^('Database connection failed:', error.message^);
echo         
echo         // If password error, try interactive input
echo         if ^(error.message.includes^('Access denied'^) ^|^| error.message.includes^('using password: NO'^)^) {
echo             console.log^('\nTrying interactive password input...'^);
echo             
echo             try {
echo                 const password = await promptForPassword^(^);
echo                 updateDbConfig^(password^);
echo                 
echo                 // Retry connection
echo                 const newConnection = await pool.getConnection^(^);
echo                 console.log^('Database connection successful!'^);
echo                 newConnection.release^(^);
echo                 rl.close^(^);
echo             } catch ^(retryError^) {
echo                 console.error^('Still failed after password input:', retryError.message^);
echo                 console.log^('\nSolutions:'^);
echo                 console.log^('1. Ensure MySQL service is running'^);
echo                 console.log^('2. Check username and password'^);
echo                 console.log^('3. Set environment variable DB_PASSWORD=your_password'^);
echo                 console.log^('4. Or modify password field in this file'^);
echo                 console.log^('\nExample:'^);
echo                 console.log^('   password: process.env.DB_PASSWORD ^|^| "your_password_here"'^);
echo                 console.log^('\nQuick fix:'^);
echo                 console.log^('   Run run.bat script to auto-configure password'^);
echo                 rl.close^(^);
echo                 process.exit^(1^);
echo             }
echo         } else {
echo             console.log^('\nSolutions:'^);
echo             console.log^('1. Ensure MySQL service is running'^);
echo             console.log^('2. Check username and password'^);
echo             console.log^('3. Set environment variable DB_PASSWORD=your_password'^);
echo             console.log^('4. Or modify password field in this file'^);
echo             console.log^('\nExample:'^);
echo             console.log^('   password: process.env.DB_PASSWORD ^|^| "your_password_here"'^);
echo             console.log^('\nQuick fix:'^);
echo             console.log^('   Run run.bat script to auto-configure password'^);
echo             rl.close^(^);
echo             process.exit^(1^);
echo         }
echo     }
echo }
echo.
echo module.exports = {
echo     pool,
echo     testConnection,
echo     updateDbConfig
echo };
) > "backend\config\database.js"

cd backend
start "Express Delivery System - Backend" cmd /k "npm start"
cd ..

echo.
echo ========================================
echo Full setup and startup completed!
echo ========================================
echo.
echo System Information:
echo - Frontend: http://localhost:3000
echo - API: http://localhost:3000/api
echo - Health Check: http://localhost:3000/api/health
echo.
echo Default Test Accounts:
echo - Username: zhangsan, Password: password123
echo - Username: lisi, Password: password123
echo - Username: wangwu, Password: password123
echo - Username: zhaoliu, Password: password123
echo.
echo Tips:
echo - Backend service runs in a separate window
echo - Close backend window to stop service
echo - If database connection fails, password will be requested interactively
echo - Browser will open automatically after successful database connection
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:exit_program
cls
echo ========================================
echo Thank you for using Express Delivery System!
echo ========================================
echo.
echo Have a great day!
echo.
echo Press any key to exit...
pause >nul
exit /b 0 