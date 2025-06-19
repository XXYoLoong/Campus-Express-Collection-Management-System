const mysql = require('mysql2/promise');
const readline = require('readline');

// 创建readline接口
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// 数据库配置
let dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'express_delivery_system',
    charset: 'utf8mb4',
    timezone: '+08:00'
};

// 创建连接池
let pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 更新数据库配置
function updateDbConfig(newPassword) {
    dbConfig.password = newPassword;
    pool = mysql.createPool({
        ...dbConfig,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
    });
}

// 交互式密码输入
function promptForPassword() {
    return new Promise((resolve) => {
        console.log('\n数据库连接失败，请输入MySQL root密码：');
        console.log('（如果没有密码请直接按回车）');
        
        rl.question('MySQL Password: ', (password) => {
            resolve(password);
        });
    });
}

// 测试数据库连接
async function testConnection() {
    try {
        const connection = await pool.getConnection();
        console.log('数据库连接成功！');
        connection.release();
        rl.close();
    } catch (error) {
        console.error('数据库连接失败：', error.message);
        
        // 如果是密码错误，尝试交互式输入
        if (error.message.includes('Access denied') || error.message.includes('using password: NO')) {
            console.log('\n尝试交互式密码输入...');
            
            try {
                const password = await promptForPassword();
                updateDbConfig(password);
                
                // 重新测试连接
                const newConnection = await pool.getConnection();
                console.log('数据库连接成功！');
                newConnection.release();
                rl.close();
            } catch (retryError) {
                console.error('密码输入后仍然连接失败：', retryError.message);
                console.log('\n解决方案：');
                console.log('1. 确保MySQL服务已启动');
                console.log('2. 检查用户名和密码是否正确');
                console.log('3. 设置环境变量 DB_PASSWORD=你的密码');
                console.log('4. 或者修改此文件中的password字段');
                console.log('\n示例：');
                console.log('   password: process.env.DB_PASSWORD || "your_password_here"');
                console.log('\n快速修复：');
                console.log('   运行 run.bat 脚本自动配置密码');
                rl.close();
                process.exit(1);
            }
        } else {
            console.log('\n解决方案：');
            console.log('1. 确保MySQL服务已启动');
            console.log('2. 检查用户名和密码是否正确');
            console.log('3. 设置环境变量 DB_PASSWORD=你的密码');
            console.log('4. 或者修改此文件中的password字段');
            console.log('\n示例：');
            console.log('   password: process.env.DB_PASSWORD || "your_password_here"');
            console.log('\n快速修复：');
            console.log('   运行 run.bat 脚本自动配置密码');
            rl.close();
            process.exit(1);
        }
    }
}

module.exports = {
    pool,
    testConnection,
    updateDbConfig
}; 
