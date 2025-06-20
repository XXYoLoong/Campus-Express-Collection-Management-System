const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { getPool } = require('../config/database');
const { generateToken, authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 用户注册
router.post('/register', [
    body('username').isLength({ min: 3, max: 50 }).withMessage('用户名长度必须在3-50个字符之间'),
    body('password').isLength({ min: 6 }).withMessage('密码长度至少6个字符'),
    body('email').isEmail().withMessage('请输入有效的邮箱地址'),
    body('phone').matches(/^1[3-9]\d{9}$/).withMessage('请输入有效的手机号码')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const { username, password, email, phone } = req.body;
        const pool = getPool();

        // 检查用户名是否已存在
        const [existingUsers] = await pool.execute(
            'SELECT uid FROM User WHERE username = ? OR email = ? OR phone = ?',
            [username, email, phone]
        );

        if (existingUsers.length > 0) {
            return res.status(400).json({ message: '用户名、邮箱或手机号已存在' });
        }

        // 加密密码
        const hashedPassword = await bcrypt.hash(password, 10);

        // 创建用户
        const [result] = await pool.execute(
            'INSERT INTO User (username, password, email, phone) VALUES (?, ?, ?, ?)',
            [username, hashedPassword, email, phone]
        );

        // 获取新创建的用户信息
        const [users] = await pool.execute(
            'SELECT uid, username, email, phone, reputation FROM User WHERE uid = ?',
            [result.insertId]
        );

        const user = users[0];
        const token = generateToken(user);

        res.status(201).json({
            message: '注册成功',
            user: {
                uid: user.uid,
                username: user.username,
                email: user.email,
                phone: user.phone,
                reputation: user.reputation
            },
            token
        });
    } catch (error) {
        console.error('注册错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 用户登录
router.post('/login', [
    body('username').notEmpty().withMessage('用户名不能为空'),
    body('password').notEmpty().withMessage('密码不能为空')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const { username, password } = req.body;
        const pool = getPool();

        // 查找用户
        const [users] = await pool.execute(
            'SELECT uid, username, password, email, phone, reputation FROM User WHERE username = ? OR email = ?',
            [username, username]
        );

        if (users.length === 0) {
            return res.status(401).json({ message: '用户名或密码错误' });
        }

        const user = users[0];

        // 验证密码
        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(401).json({ message: '用户名或密码错误' });
        }

        // 生成token
        const token = generateToken(user);

        res.json({
            message: '登录成功',
            user: {
                uid: user.uid,
                username: user.username,
                email: user.email,
                phone: user.phone,
                reputation: user.reputation
            },
            token
        });
    } catch (error) {
        console.error('登录错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取当前用户信息
router.get('/profile', authenticateToken, async (req, res) => {
    try {
        res.json({
            message: '获取用户信息成功',
            user: req.user
        });
    } catch (error) {
        console.error('获取用户信息错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 修改密码
router.put('/change-password', authenticateToken, [
    body('oldPassword').notEmpty().withMessage('原密码不能为空'),
    body('newPassword').isLength({ min: 6 }).withMessage('新密码长度至少6个字符')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const { oldPassword, newPassword } = req.body;
        const userId = req.user.uid;
        const pool = getPool();

        // 获取用户当前密码
        const [users] = await pool.execute(
            'SELECT password FROM User WHERE uid = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({ message: '用户不存在' });
        }

        // 验证原密码
        const isValidPassword = await bcrypt.compare(oldPassword, users[0].password);
        if (!isValidPassword) {
            return res.status(400).json({ message: '原密码错误' });
        }

        // 加密新密码
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);

        // 更新密码
        await pool.execute(
            'UPDATE User SET password = ? WHERE uid = ?',
            [hashedNewPassword, userId]
        );

        res.json({ message: '密码修改成功' });
    } catch (error) {
        console.error('修改密码错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

module.exports = router; 