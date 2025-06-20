const jwt = require('jsonwebtoken');
const { getPool } = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// 验证JWT token
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ message: '访问令牌缺失' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        
        // 验证用户是否仍然存在
        const pool = getPool();
        const [users] = await pool.execute(
            'SELECT uid, username, email, phone, reputation FROM User WHERE uid = ?',
            [decoded.uid]
        );

        if (users.length === 0) {
            return res.status(401).json({ message: '用户不存在' });
        }

        req.user = users[0];
        next();
    } catch (error) {
        return res.status(403).json({ message: '无效的访问令牌' });
    }
};

// 生成JWT token
const generateToken = (user) => {
    return jwt.sign(
        { uid: user.uid, username: user.username },
        JWT_SECRET,
        { expiresIn: '24h' }
    );
};

module.exports = {
    authenticateToken,
    generateToken
}; 