-- 学校快递任务代取管理系统数据库初始化脚本
-- MySQL 8.0+

-- 创建数据库
CREATE DATABASE IF NOT EXISTS express_delivery_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE express_delivery_system;

-- 1. 用户表 (User)
CREATE TABLE IF NOT EXISTS User (
    uid INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    reputation DECIMAL(3,1) DEFAULT 5.0 COMMENT '信誉分',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 2. 快递任务表 (DeliveryTask)
CREATE TABLE IF NOT EXISTS DeliveryTask (
    tid INT AUTO_INCREMENT PRIMARY KEY COMMENT '任务ID',
    publisherId INT NOT NULL COMMENT '发布者ID',
    company VARCHAR(50) NOT NULL COMMENT '快递公司',
    pickupPlace VARCHAR(200) NOT NULL COMMENT '取件地点',
    code VARCHAR(50) NOT NULL COMMENT '取件码',
    reward DECIMAL(8,2) NOT NULL COMMENT '酬金',
    deadline TIMESTAMP NOT NULL COMMENT '截止时间',
    status ENUM('pending', 'accepted', 'completed', 'cancelled') DEFAULT 'pending' COMMENT '任务状态',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    FOREIGN KEY (publisherId) REFERENCES User(uid) ON DELETE CASCADE,
    INDEX idx_publisher (publisherId),
    INDEX idx_status (status),
    INDEX idx_deadline (deadline)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递任务表';

-- 3. 任务接取记录表 (TaskAssignment)
CREATE TABLE IF NOT EXISTS TaskAssignment (
    assignmentId INT AUTO_INCREMENT PRIMARY KEY COMMENT '接单记录ID',
    taskId INT NOT NULL UNIQUE COMMENT '任务ID',
    takerId INT NOT NULL COMMENT '接单者ID',
    acceptTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '接单时间',
    finishTime TIMESTAMP NULL COMMENT '完成时间',
    status ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress' COMMENT '状态',
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE,
    FOREIGN KEY (takerId) REFERENCES User(uid) ON DELETE CASCADE,
    INDEX idx_task (taskId),
    INDEX idx_taker (takerId),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务接取记录表';

-- 4. 评价表 (Rating)
CREATE TABLE IF NOT EXISTS Rating (
    rid INT AUTO_INCREMENT PRIMARY KEY COMMENT '评价ID',
    reviewerId INT NOT NULL COMMENT '评价者ID',
    revieweeId INT NOT NULL COMMENT '被评者ID',
    taskId INT NOT NULL COMMENT '来源任务ID',
    score TINYINT NOT NULL CHECK (score >= 1 AND score <= 5) COMMENT '分数(1-5)',
    comment TEXT COMMENT '评论',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '时间',
    FOREIGN KEY (reviewerId) REFERENCES User(uid) ON DELETE CASCADE,
    FOREIGN KEY (revieweeId) REFERENCES User(uid) ON DELETE CASCADE,
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE,
    INDEX idx_reviewer (reviewerId),
    INDEX idx_reviewee (revieweeId),
    INDEX idx_task (taskId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评价表';

-- 创建视图：已接任务视图
CREATE OR REPLACE VIEW View_ReceivedTasks AS
SELECT 
    t.tid,
    t.publisherId,
    t.company,
    t.pickupPlace,
    t.code,
    t.reward,
    t.deadline,
    t.status as taskStatus,
    t.createTime,
    u.username as publisherName,
    u.phone as publisherPhone,
    ta.assignmentId,
    ta.takerId,
    ta.acceptTime,
    ta.status as assignmentStatus,
    taker.username as takerName,
    taker.phone as takerPhone
FROM DeliveryTask t
JOIN User u ON t.publisherId = u.uid
JOIN TaskAssignment ta ON t.tid = ta.taskId
JOIN User taker ON ta.takerId = taker.uid;

-- 创建视图：待接任务视图
CREATE OR REPLACE VIEW View_AvailableTasks AS
SELECT 
    t.tid,
    t.publisherId,
    t.company,
    t.pickupPlace,
    t.code,
    t.reward,
    t.deadline,
    t.status,
    t.createTime,
    u.username as publisherName,
    u.reputation as publisherReputation
FROM DeliveryTask t
JOIN User u ON t.publisherId = u.uid
WHERE t.status = 'pending' AND t.deadline > NOW();

-- 创建视图：用户评价统计视图
CREATE OR REPLACE VIEW View_UserRatingStats AS
SELECT 
    u.uid,
    u.username,
    u.reputation,
    COUNT(r.rid) as totalRatings,
    AVG(r.score) as avgScore,
    COUNT(CASE WHEN r.score >= 4 THEN 1 END) as goodRatings,
    COUNT(CASE WHEN r.score <= 2 THEN 1 END) as badRatings
FROM User u
LEFT JOIN Rating r ON u.uid = r.revieweeId
GROUP BY u.uid, u.username, u.reputation;

-- 存储过程：接单功能
DELIMITER //
CREATE PROCEDURE AcceptTask(IN p_takerId INT, IN p_taskId INT)
BEGIN
    DECLARE v_taskStatus VARCHAR(20);
    DECLARE v_publisherId INT;
    DECLARE v_reward DECIMAL(8,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 检查任务是否存在且状态为待接单
    SELECT status, publisherId, reward INTO v_taskStatus, v_publisherId, v_reward
    FROM DeliveryTask 
    WHERE tid = p_taskId AND status = 'pending' AND deadline > NOW()
    FOR UPDATE;
    
    IF v_taskStatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务不存在或已被接取';
    END IF;
    
    -- 检查是否是自己发布的任务
    IF v_publisherId = p_takerId THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '不能接取自己发布的任务';
    END IF;
    
    -- 更新任务状态
    UPDATE DeliveryTask SET status = 'accepted' WHERE tid = p_taskId;
    
    -- 创建接单记录
    INSERT INTO TaskAssignment (taskId, takerId, status) VALUES (p_taskId, p_takerId, 'in_progress');
    
    COMMIT;
    
    SELECT '接单成功' as message;
END //
DELIMITER ;

-- 存储过程：完成任务
DELIMITER //
CREATE PROCEDURE CompleteTask(IN p_taskId INT, IN p_takerId INT)
BEGIN
    DECLARE v_assignmentId INT;
    DECLARE v_publisherId INT;
    DECLARE v_reward DECIMAL(8,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 检查任务记录
    SELECT ta.assignmentId, dt.publisherId, dt.reward INTO v_assignmentId, v_publisherId, v_reward
    FROM TaskAssignment ta
    JOIN DeliveryTask dt ON ta.taskId = dt.tid
    WHERE ta.taskId = p_taskId AND ta.takerId = p_takerId AND ta.status = 'in_progress'
    FOR UPDATE;
    
    IF v_assignmentId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
    END IF;
    
    -- 更新任务状态
    UPDATE DeliveryTask SET status = 'completed' WHERE tid = p_taskId;
    
    -- 更新接单记录
    UPDATE TaskAssignment SET status = 'completed', finishTime = NOW() WHERE assignmentId = v_assignmentId;
    
    COMMIT;
    
    SELECT '任务完成' as message;
END //
DELIMITER ;

-- 存储过程：取消任务
DELIMITER //
CREATE PROCEDURE CancelTask(IN p_taskId INT, IN p_userId INT, IN p_userType ENUM('publisher', 'taker'))
BEGIN
    DECLARE v_assignmentId INT;
    DECLARE v_takerId INT;
    DECLARE v_publisherId INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF p_userType = 'publisher' THEN
        -- 发布者取消任务
        SELECT ta.assignmentId, ta.takerId INTO v_assignmentId, v_takerId
        FROM TaskAssignment ta
        JOIN DeliveryTask dt ON ta.taskId = dt.tid
        WHERE dt.tid = p_taskId AND dt.publisherId = p_userId AND ta.status = 'in_progress'
        FOR UPDATE;
        
        IF v_assignmentId IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
        END IF;
        
        -- 更新任务状态
        UPDATE DeliveryTask SET status = 'cancelled' WHERE tid = p_taskId;
        
        -- 更新接单记录
        UPDATE TaskAssignment SET status = 'cancelled' WHERE assignmentId = v_assignmentId;
        
    ELSE
        -- 接单者取消任务
        SELECT ta.assignmentId, dt.publisherId INTO v_assignmentId, v_publisherId
        FROM TaskAssignment ta
        JOIN DeliveryTask dt ON ta.taskId = dt.tid
        WHERE ta.taskId = p_taskId AND ta.takerId = p_userId AND ta.status = 'in_progress'
        FOR UPDATE;
        
        IF v_assignmentId IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
        END IF;
        
        -- 更新任务状态
        UPDATE DeliveryTask SET status = 'pending' WHERE tid = p_taskId;
        
        -- 删除接单记录
        DELETE FROM TaskAssignment WHERE assignmentId = v_assignmentId;
    END IF;
    
    COMMIT;
    
    SELECT '任务取消成功' as message;
END //
DELIMITER ;

-- 存储过程：添加评价并更新信誉分
DELIMITER //
CREATE PROCEDURE AddRating(
    IN p_reviewerId INT, 
    IN p_revieweeId INT, 
    IN p_taskId INT, 
    IN p_score TINYINT, 
    IN p_comment TEXT
)
BEGIN
    DECLARE v_avgScore DECIMAL(3,1);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 检查评分范围
    IF p_score < 1 OR p_score > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '评分必须在1-5之间';
    END IF;
    
    -- 添加评价
    INSERT INTO Rating (reviewerId, revieweeId, taskId, score, comment) 
    VALUES (p_reviewerId, p_revieweeId, p_taskId, p_score, p_comment);
    
    -- 计算新的平均信誉分
    SELECT AVG(score) INTO v_avgScore
    FROM Rating 
    WHERE revieweeId = p_revieweeId;
    
    -- 更新用户信誉分
    UPDATE User SET reputation = v_avgScore WHERE uid = p_revieweeId;
    
    COMMIT;
    
    SELECT '评价添加成功' as message;
END //
DELIMITER ;

-- 插入测试数据（使用英文用户名和加密密码）
-- 注意：这些密码是 'password123' 的bcrypt加密版本
INSERT INTO User (username, password, email, phone, reputation) VALUES
('zhangsan', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'zhangsan@example.com', '13800138001', 5.0),
('lisi', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'lisi@example.com', '13800138002', 4.8),
('wangwu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'wangwu@example.com', '13800138003', 4.5),
('zhaoliu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'zhaoliu@example.com', '13800138004', 4.2);

INSERT INTO DeliveryTask (publisherId, company, pickupPlace, code, reward, deadline, status) VALUES
(1, '顺丰快递', '第一教学楼快递点', 'SF123456', 5.00, DATE_ADD(NOW(), INTERVAL 2 DAY), 'pending'),
(2, '圆通快递', '图书馆快递柜', 'YT789012', 8.00, DATE_ADD(NOW(), INTERVAL 1 DAY), 'pending'),
(3, '中通快递', '学生公寓快递点', 'ZT345678', 6.00, DATE_ADD(NOW(), INTERVAL 3 DAY), 'pending'),
(1, '申通快递', '食堂快递点', 'ST901234', 7.00, DATE_ADD(NOW(), INTERVAL 1 DAY), 'pending');

-- 显示创建结果
SELECT '数据库初始化完成！' as message; 