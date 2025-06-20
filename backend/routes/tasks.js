const express = require('express');
const { body, validationResult } = require('express-validator');
const { getPool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 发布任务
router.post('/', authenticateToken, [
    body('company').notEmpty().withMessage('快递公司不能为空'),
    body('pickupPlace').notEmpty().withMessage('取件地点不能为空'),
    body('code').notEmpty().withMessage('取件码不能为空'),
    body('reward').isFloat({ min: 0.01 }).withMessage('酬金必须大于0'),
    body('deadline').isISO8601().withMessage('截止时间格式不正确')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const { company, pickupPlace, code, reward, deadline } = req.body;
        const publisherId = req.user.uid;

        // 检查截止时间是否在未来
        const deadlineDate = new Date(deadline);
        if (deadlineDate <= new Date()) {
            return res.status(400).json({ message: '截止时间必须在未来' });
        }

        const pool = getPool();

        // 创建任务
        const [result] = await pool.execute(
            'INSERT INTO DeliveryTask (publisherId, company, pickupPlace, code, reward, deadline) VALUES (?, ?, ?, ?, ?, ?)',
            [publisherId, company, pickupPlace, code, reward, deadlineDate]
        );

        // 获取新创建的任务信息
        const [tasks] = await pool.execute(
            'SELECT * FROM DeliveryTask WHERE tid = ?',
            [result.insertId]
        );

        res.status(201).json({
            message: '任务发布成功',
            task: tasks[0]
        });
    } catch (error) {
        console.error('发布任务错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取待接任务列表
router.get('/available', async (req, res) => {
    try {
        const pool = getPool();
        const [tasks] = await pool.execute(
            'SELECT * FROM View_AvailableTasks ORDER BY createTime DESC'
        );

        res.json({
            message: '获取待接任务列表成功',
            tasks
        });
    } catch (error) {
        console.error('获取待接任务列表错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取我发布的任务
router.get('/published', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.uid;
        const pool = getPool();
        const [tasks] = await pool.execute(
            'SELECT * FROM DeliveryTask WHERE publisherId = ? ORDER BY createTime DESC',
            [userId]
        );

        res.json({
            message: '获取发布的任务成功',
            tasks
        });
    } catch (error) {
        console.error('获取发布的任务错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 获取我接的任务
router.get('/accepted', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.uid;
        const pool = getPool();
        const [tasks] = await pool.execute(
            'SELECT * FROM View_ReceivedTasks WHERE takerId = ? ORDER BY acceptTime DESC',
            [userId]
        );

        res.json({
            message: '获取接取的任务成功',
            tasks
        });
    } catch (error) {
        console.error('获取接取的任务错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 接单
router.post('/:taskId/accept', authenticateToken, async (req, res) => {
    try {
        const taskId = parseInt(req.params.taskId);
        const takerId = req.user.uid;
        const pool = getPool();

        // 调用存储过程接单
        const [result] = await pool.execute(
            'CALL AcceptTask(?, ?)',
            [takerId, taskId]
        );

        res.json({
            message: '接单成功',
            result: result[0][0]
        });
    } catch (error) {
        console.error('接单错误：', error);
        if (error.code === 'ER_SIGNAL_EXCEPTION') {
            res.status(400).json({ message: error.message });
        } else {
            res.status(500).json({ message: '服务器内部错误' });
        }
    }
});

// 完成任务
router.post('/:taskId/complete', authenticateToken, async (req, res) => {
    try {
        const taskId = parseInt(req.params.taskId);
        const takerId = req.user.uid;
        const pool = getPool();

        // 调用存储过程完成任务
        const [result] = await pool.execute(
            'CALL CompleteTask(?, ?)',
            [taskId, takerId]
        );

        res.json({
            message: '任务完成',
            result: result[0][0]
        });
    } catch (error) {
        console.error('完成任务错误：', error);
        if (error.code === 'ER_SIGNAL_EXCEPTION') {
            res.status(400).json({ message: error.message });
        } else {
            res.status(500).json({ message: '服务器内部错误' });
        }
    }
});

// 取消任务
router.post('/:taskId/cancel', authenticateToken, [
    body('userType').isIn(['publisher', 'taker']).withMessage('用户类型必须是publisher或taker')
], async (req, res) => {
    try {
        // 验证输入
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: '输入验证失败', errors: errors.array() });
        }

        const taskId = parseInt(req.params.taskId);
        const userId = req.user.uid;
        const { userType } = req.body;
        const pool = getPool();

        // 调用存储过程取消任务
        const [result] = await pool.execute(
            'CALL CancelTask(?, ?, ?)',
            [taskId, userId, userType]
        );

        res.json({
            message: '任务取消成功',
            result: result[0][0]
        });
    } catch (error) {
        console.error('取消任务错误：', error);
        if (error.code === 'ER_SIGNAL_EXCEPTION') {
            res.status(400).json({ message: error.message });
        } else {
            res.status(500).json({ message: '服务器内部错误' });
        }
    }
});

// 获取任务详情
router.get('/:taskId', async (req, res) => {
    try {
        const taskId = parseInt(req.params.taskId);
        const pool = getPool();

        const [tasks] = await pool.execute(
            'SELECT * FROM DeliveryTask WHERE tid = ?',
            [taskId]
        );

        if (tasks.length === 0) {
            return res.status(404).json({ message: '任务不存在' });
        }

        res.json({
            message: '获取任务详情成功',
            task: tasks[0]
        });
    } catch (error) {
        console.error('获取任务详情错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

// 删除任务（仅发布者可以删除未接单的任务）
router.delete('/:taskId', authenticateToken, async (req, res) => {
    try {
        const taskId = parseInt(req.params.taskId);
        const userId = req.user.uid;

        // 检查任务是否存在且属于当前用户
        const [tasks] = await pool.execute(
            'SELECT status FROM DeliveryTask WHERE tid = ? AND publisherId = ?',
            [taskId, userId]
        );

        if (tasks.length === 0) {
            return res.status(404).json({ message: '任务不存在或无权限删除' });
        }

        if (tasks[0].status !== '待接单') {
            return res.status(400).json({ message: '只能删除未接单的任务' });
        }

        // 删除任务
        await pool.execute(
            'DELETE FROM DeliveryTask WHERE tid = ?',
            [taskId]
        );

        res.json({ message: '任务删除成功' });
    } catch (error) {
        console.error('删除任务错误：', error);
        res.status(500).json({ message: '服务器内部错误' });
    }
});

module.exports = router; 