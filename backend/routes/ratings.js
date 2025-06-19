const express = require('express');
const { body, validationResult } = require('express-validator');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 添加评价
router.post('/', authenticateToken, [
    body('revieweeId').isInt({ min: 1 }).withMessage('被评者ID必须是正整数'),
    body('taskId').isInt({ min: 1 }).withMessage('任务ID必须是正整数'),
    body('score').isInt({ min: 1, max: 5 }).withMessage('评分必须在1-5之间'),
    body('comment').optional().isLength({ max: 500 }).withMessage('评论长度不能超过500字符')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const { revieweeId, taskId, score, comment } = req.body;
        const reviewerId = req.user.uid;

        // 检查是否不能评价自己
        if (reviewerId === revieweeId) {
            return res.status(400).json({ message: '不能评价自己' });
        }

        // 检查任务是否存在且已完成
        const [tasks] = await pool.execute(
            'SELECT status FROM DeliveryTask WHERE tid = ?',
            [taskId]
        );

        if (tasks.length === 0) {
            return res.status(404).json({ message: '任务不存在' });
        }

        if (tasks[0].status !== '已完成') {
            return res.status(400).json({ message: '只能对已完成的任务进行评价' });
        }

        // 检查是否已经评价过
        const [existingRatings] = await pool.execute(
            'SELECT rid FROM Rating WHERE reviewerId = ? AND taskId = ?',
            [reviewerId, taskId]
        );

        if (existingRatings.length > 0) {
            return res.status(400).json({ message: '已经对该任务进行过评价' });
        }

        // 调用存储过程添加评价
        const [result] = await pool.execute(
            'CALL AddRating(?, ?, ?, ?, ?)',
            [reviewerId, revieweeId, taskId, score, comment]
        );

        res.status(201).json({
            message: '评价添加成功',
            result: result[0][0]
        });
    } catch (error) {
        console.error('添加评价错误：', error);
        if (error.code === 'ER_SIGNAL_EXCEPTION') {
            res.status(400).json({ message: error.message });
        } else {
            res.status(500).json({ message: '服务器内部错误' });
        }
    }
});

// 获取用户的评价历史
router.get('/user/:userId', async (req, res) => {
    try {
        const userId = parseInt(req.params.userId);

        // 获取用户收到的评价
        const [receivedRatings] = await pool.execute(
            `SELECT r.*, u.username as reviewerName, dt.company, dt.pickupPlace 
             FROM Rating r 
             JOIN User u ON r.reviewerId = u.uid 
             JOIN DeliveryTask dt ON r.taskId = dt.tid 
             WHERE r.revieweeId = ? 
             ORDER BY r.createTime DESC`,
            [userId]
        );

        // 获取用户发出的评价
        const [givenRatings] = await pool.execute(
            `SELECT r.*, u.username as revieweeName, dt.company, dt.pickupPlace 
             FROM Rating r 
             JOIN User u ON r.revieweeId = u.uid 
             JOIN DeliveryTask dt ON r.taskId = dt.tid 
             WHERE r.reviewerId = ? 
             ORDER BY r.createTime DESC`,
            [userId]
        );

        res.json({
            message: '获取评价历史成功',
            receivedRatings,
            givenRatings
        });
    } catch (error) {
        console.error('获取评价历史错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取我的评价历史
router.get('/my-ratings', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.uid;

        // 获取我收到的评价
        const [receivedRatings] = await pool.execute(
            `SELECT r.*, u.username as reviewerName, dt.company, dt.pickupPlace 
             FROM Rating r 
             JOIN User u ON r.reviewerId = u.uid 
             JOIN DeliveryTask dt ON r.taskId = dt.tid 
             WHERE r.revieweeId = ? 
             ORDER BY r.createTime DESC`,
            [userId]
        );

        // 获取我发出的评价
        const [givenRatings] = await pool.execute(
            `SELECT r.*, u.username as revieweeName, dt.company, dt.pickupPlace 
             FROM Rating r 
             JOIN User u ON r.revieweeId = u.uid 
             JOIN DeliveryTask dt ON r.taskId = dt.tid 
             WHERE r.reviewerId = ? 
             ORDER BY r.createTime DESC`,
            [userId]
        );

        res.json({
            message: '获取我的评价历史成功',
            receivedRatings,
            givenRatings
        });
    } catch (error) {
        console.error('获取我的评价历史错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取任务相关的评价
router.get('/task/:taskId', async (req, res) => {
    try {
        const taskId = parseInt(req.params.taskId);

        const [ratings] = await pool.execute(
            `SELECT r.*, 
                    reviewer.username as reviewerName, 
                    reviewee.username as revieweeName,
                    dt.company, dt.pickupPlace
             FROM Rating r 
             JOIN User reviewer ON r.reviewerId = reviewer.uid 
             JOIN User reviewee ON r.revieweeId = reviewee.uid 
             JOIN DeliveryTask dt ON r.taskId = dt.tid 
             WHERE r.taskId = ? 
             ORDER BY r.createTime DESC`,
            [taskId]
        );

        res.json({
            message: '获取任务评价成功',
            ratings
        });
    } catch (error) {
        console.error('获取任务评价错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取用户评价统计
router.get('/stats/:userId', async (req, res) => {
    try {
        const userId = parseInt(req.params.userId);

        const [stats] = await pool.execute(
            'SELECT * FROM View_UserRatingStats WHERE uid = ?',
            [userId]
        );

        if (stats.length === 0) {
            return res.status(404).json({ message: '用户不存在' });
        }

        res.json({
            message: '获取用户评价统计成功',
            stats: stats[0]
        });
    } catch (error) {
        console.error('获取用户评价统计错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 删除评价（仅评价者可以删除自己的评价）
router.delete('/:ratingId', authenticateToken, async (req, res) => {
    try {
        const ratingId = parseInt(req.params.ratingId);
        const userId = req.user.uid;

        // 检查评价是否存在且属于当前用户
        const [ratings] = await pool.execute(
            'SELECT rid, revieweeId, score FROM Rating WHERE rid = ? AND reviewerId = ?',
            [ratingId, userId]
        );

        if (ratings.length === 0) {
            return res.status(404).json({ message: '评价不存在或无权限删除' });
        }

        const rating = ratings[0];

        // 删除评价
        await pool.execute(
            'DELETE FROM Rating WHERE rid = ?',
            [ratingId]
        );

        // 重新计算被评者的信誉分
        const [avgScore] = await pool.execute(
            'SELECT AVG(score) as avgScore FROM Rating WHERE revieweeId = ?',
            [rating.revieweeId]
        );

        const newReputation = avgScore[0].avgScore || 5.0;

        await pool.execute(
            'UPDATE User SET reputation = ? WHERE uid = ?',
            [newReputation, rating.revieweeId]
        );

        res.json({ message: '评价删除成功' });
    } catch (error) {
        console.error('删除评价错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

module.exports = router; 