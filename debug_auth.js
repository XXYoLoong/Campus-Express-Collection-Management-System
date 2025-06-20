const jwt = require('jsonwebtoken');
const { getPool } = require('./backend/config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

async function debugAuth() {
    try {
        console.log('=== 认证问题诊断 ===');
        
        // 1. 检查数据库连接
        console.log('1. 检查数据库连接...');
        const pool = getPool();
        const [users] = await pool.execute('SELECT uid, username FROM User LIMIT 1');
        
        if (users.length === 0) {
            console.log('❌ 数据库中没有用户');
            console.log('请先注册一个用户');
            return;
        }
        
        const testUser = users[0];
        console.log(`✅ 找到用户: ${testUser.username} (ID: ${testUser.uid})`);
        
        // 2. 测试token生成和验证
        console.log('\n2. 测试token生成和验证...');
        const token = jwt.sign(
            { uid: testUser.uid, username: testUser.username },
            JWT_SECRET,
            { expiresIn: '24h' }
        );
        console.log(`✅ Token生成成功`);
        
        const decoded = jwt.verify(token, JWT_SECRET);
        console.log(`✅ Token验证成功:`, decoded);
        
        // 3. 测试用户查询
        console.log('\n3. 测试用户查询...');
        const [userCheck] = await pool.execute(
            'SELECT uid, username, email, phone, reputation FROM User WHERE uid = ?',
            [decoded.uid]
        );
        
        if (userCheck.length > 0) {
            console.log(`✅ 用户查询成功:`, userCheck[0]);
        } else {
            console.log('❌ 用户查询失败');
        }
        
        console.log('\n=== 诊断完成 ===');
        console.log('\n如果上述测试都通过，问题可能在于：');
        console.log('1. 前端token存储问题');
        console.log('2. 请求头格式问题');
        console.log('3. 服务器重启后token失效');
        
    } catch (error) {
        console.error('❌ 诊断失败:', error);
    }
}

debugAuth(); 