-- ========================================
-- 学校快递任务代取管理系统数据库初始化脚本
-- Campus Express Collection Management System Database Initialization Script
-- ========================================
-- 
-- 系统概述：
-- 本系统为学校师生提供快递代取服务，支持用户发布任务、接取任务、完成任务和评价功能
-- 主要功能模块：用户管理、任务管理、接单管理、评价系统
-- 
-- 数据库版本要求：MySQL 8.0+
-- 字符集：utf8mb4 (支持完整的Unicode字符，包括emoji)
-- 排序规则：utf8mb4_unicode_ci (不区分大小写的Unicode排序)
-- 
-- 作者：快递代取系统开发团队
-- 创建时间：2024年
-- 最后更新：2025年
-- ========================================

-- ========================================
-- 第一步：创建数据库
-- ========================================
-- 使用 IF NOT EXISTS 确保脚本可以重复执行而不会报错
-- CHARACTER SET utf8mb4 确保支持完整的Unicode字符集
-- COLLATE utf8mb4_unicode_ci 提供不区分大小写的排序规则
CREATE DATABASE IF NOT EXISTS express_delivery_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 切换到新创建的数据库
USE express_delivery_system;

-- ========================================
-- 第二步：创建核心数据表
-- ========================================

-- 1. 用户表 (User) - 存储系统用户信息
-- 功能：记录所有注册用户的基本信息、认证信息和信誉评分
-- 业务场景：用户注册、登录、个人信息管理、信誉评价
CREATE TABLE IF NOT EXISTS User (
    -- 用户唯一标识符，自增主键
    uid INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID - 系统自动生成的唯一标识符',
    
    -- 用户名，用于登录和显示，必须唯一
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名 - 用于登录和显示，长度限制50字符，必须唯一',
    
    -- 密码字段，存储加密后的密码（使用bcrypt加密）
    password VARCHAR(255) NOT NULL COMMENT '密码 - 使用bcrypt算法加密存储，长度255字符确保加密后不会截断',
    
    -- 邮箱地址，用于找回密码和通知，必须唯一
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱 - 用于找回密码和系统通知，必须唯一',
    
    -- 手机号码，用于联系和验证，必须唯一
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号 - 用于联系和身份验证，必须唯一',
    
    -- 信誉评分，范围0.0-10.0，默认5.0分
    reputation DECIMAL(3,1) DEFAULT 5.0 COMMENT '信誉分 - 用户信用评分，范围0.0-10.0，默认5.0分，根据评价自动计算',
    
    -- 用户注册时间，自动记录
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间 - 用户首次注册的时间戳，自动记录',
    
    -- 创建索引以提高查询性能
    -- 用户名索引：用于登录验证
    INDEX idx_username (username) COMMENT '用户名索引 - 加速登录验证查询',
    -- 邮箱索引：用于邮箱验证和找回密码
    INDEX idx_email (email) COMMENT '邮箱索引 - 加速邮箱验证和找回密码查询',
    -- 手机号索引：用于手机号验证
    INDEX idx_phone (phone) COMMENT '手机号索引 - 加速手机号验证查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表 - 存储系统所有用户的基本信息、认证信息和信誉评分';

-- 2. 快递任务表 (DeliveryTask) - 存储用户发布的快递代取任务
-- 功能：记录任务的详细信息、状态和截止时间
-- 业务场景：发布任务、查看任务列表、任务状态管理
CREATE TABLE IF NOT EXISTS DeliveryTask (
    -- 任务唯一标识符，自增主键
    tid INT AUTO_INCREMENT PRIMARY KEY COMMENT '任务ID - 系统自动生成的任务唯一标识符',
    
    -- 发布者ID，关联用户表
    publisherId INT NOT NULL COMMENT '发布者ID - 发布任务的用户ID，关联User表的uid字段',
    
    -- 快递公司名称，如顺丰、圆通等
    company VARCHAR(50) NOT NULL COMMENT '快递公司 - 快递公司名称，如顺丰快递、圆通快递等',
    
    -- 取件地点，详细描述取件位置
    pickupPlace VARCHAR(200) NOT NULL COMMENT '取件地点 - 详细的取件位置描述，如第一教学楼快递点、图书馆快递柜等',
    
    -- 取件码，用于取件验证
    code VARCHAR(50) NOT NULL COMMENT '取件码 - 快递取件验证码，用于取件时验证身份',
    
    -- 任务酬金，精确到分
    reward DECIMAL(8,2) NOT NULL COMMENT '酬金 - 任务完成后的奖励金额，精确到分，范围0.01-999999.99',
    
    -- 任务截止时间，超过此时间任务自动失效
    deadline TIMESTAMP NOT NULL COMMENT '截止时间 - 任务的有效期限，超过此时间任务自动失效',
    
    -- 任务状态：待接单、已接单、已完成、已取消
    status ENUM('pending', 'accepted', 'completed', 'cancelled') DEFAULT 'pending' COMMENT '任务状态 - pending:待接单, accepted:已接单, completed:已完成, cancelled:已取消',
    
    -- 任务发布时间，自动记录
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间 - 任务创建的时间戳，自动记录',
    
    -- 外键约束：确保发布者ID在用户表中存在，级联删除
    FOREIGN KEY (publisherId) REFERENCES User(uid) ON DELETE CASCADE COMMENT '外键约束 - 关联User表，确保数据完整性，级联删除',
    
    -- 创建索引以提高查询性能
    -- 发布者索引：用于查询用户发布的任务
    INDEX idx_publisher (publisherId) COMMENT '发布者索引 - 加速查询用户发布的任务',
    -- 状态索引：用于按状态筛选任务
    INDEX idx_status (status) COMMENT '状态索引 - 加速按状态筛选任务',
    -- 截止时间索引：用于查询即将过期的任务
    INDEX idx_deadline (deadline) COMMENT '截止时间索引 - 加速查询即将过期的任务'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递任务表 - 存储用户发布的快递代取任务信息，包括任务详情、状态和截止时间';

-- 3. 任务接取记录表 (TaskAssignment) - 记录任务的接取情况
-- 功能：记录谁接取了哪个任务，以及接取和完成的时间
-- 业务场景：接单管理、任务进度跟踪、完成时间统计
CREATE TABLE IF NOT EXISTS TaskAssignment (
    -- 接单记录唯一标识符，自增主键
    assignmentId INT AUTO_INCREMENT PRIMARY KEY COMMENT '接单记录ID - 系统自动生成的接单记录唯一标识符',
    
    -- 任务ID，关联任务表，确保一个任务只能被接取一次
    taskId INT NOT NULL UNIQUE COMMENT '任务ID - 关联DeliveryTask表的tid字段，UNIQUE确保一个任务只能被接取一次',
    
    -- 接单者ID，关联用户表
    takerId INT NOT NULL COMMENT '接单者ID - 接取任务的用户ID，关联User表的uid字段',
    
    -- 接单时间，自动记录
    acceptTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '接单时间 - 用户接取任务的时间戳，自动记录',
    
    -- 完成时间，任务完成后记录
    finishTime TIMESTAMP NULL COMMENT '完成时间 - 任务完成的时间戳，NULL表示尚未完成',
    
    -- 接单状态：进行中、已完成、已取消
    status ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress' COMMENT '接单状态 - in_progress:进行中, completed:已完成, cancelled:已取消',
    
    -- 外键约束：确保任务ID在任务表中存在，级联删除
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE COMMENT '外键约束 - 关联DeliveryTask表，确保数据完整性，级联删除',
    
    -- 外键约束：确保接单者ID在用户表中存在，级联删除
    FOREIGN KEY (takerId) REFERENCES User(uid) ON DELETE CASCADE COMMENT '外键约束 - 关联User表，确保数据完整性，级联删除',
    
    -- 创建索引以提高查询性能
    -- 任务索引：用于查询特定任务的接取情况
    INDEX idx_task (taskId) COMMENT '任务索引 - 加速查询特定任务的接取情况',
    -- 接单者索引：用于查询用户接取的任务
    INDEX idx_taker (takerId) COMMENT '接单者索引 - 加速查询用户接取的任务',
    -- 状态索引：用于按状态筛选接单记录
    INDEX idx_status (status) COMMENT '状态索引 - 加速按状态筛选接单记录'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务接取记录表 - 记录任务的接取情况，包括接单者、接单时间、完成时间和状态';

-- 4. 评价表 (Rating) - 存储用户之间的评价信息
-- 功能：记录任务完成后的评价，用于计算用户信誉分
-- 业务场景：任务评价、信誉分计算、用户信用管理
CREATE TABLE IF NOT EXISTS Rating (
    -- 评价唯一标识符，自增主键
    rid INT AUTO_INCREMENT PRIMARY KEY COMMENT '评价ID - 系统自动生成的评价唯一标识符',
    
    -- 评价者ID，关联用户表
    reviewerId INT NOT NULL COMMENT '评价者ID - 发起评价的用户ID，关联User表的uid字段',
    
    -- 被评价者ID，关联用户表
    revieweeId INT NOT NULL COMMENT '被评者ID - 被评价的用户ID，关联User表的uid字段',
    
    -- 来源任务ID，关联任务表
    taskId INT NOT NULL COMMENT '来源任务ID - 评价来源的任务ID，关联DeliveryTask表的tid字段',
    
    -- 评分，范围1-5分
    score TINYINT NOT NULL CHECK (score >= 1 AND score <= 5) COMMENT '分数 - 评价分数，范围1-5分，1分最差，5分最好',
    
    -- 评价内容，可选
    comment TEXT COMMENT '评论 - 评价的文字内容，可选字段，用于详细描述评价原因',
    
    -- 评价时间，自动记录
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '时间 - 评价创建的时间戳，自动记录',
    
    -- 外键约束：确保评价者ID在用户表中存在，级联删除
    FOREIGN KEY (reviewerId) REFERENCES User(uid) ON DELETE CASCADE COMMENT '外键约束 - 关联User表(评价者)，确保数据完整性，级联删除',
    
    -- 外键约束：确保被评价者ID在用户表中存在，级联删除
    FOREIGN KEY (revieweeId) REFERENCES User(uid) ON DELETE CASCADE COMMENT '外键约束 - 关联User表(被评价者)，确保数据完整性，级联删除',
    
    -- 外键约束：确保任务ID在任务表中存在，级联删除
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE COMMENT '外键约束 - 关联DeliveryTask表，确保数据完整性，级联删除',
    
    -- 创建索引以提高查询性能
    -- 评价者索引：用于查询用户发出的评价
    INDEX idx_reviewer (reviewerId) COMMENT '评价者索引 - 加速查询用户发出的评价',
    -- 被评价者索引：用于查询用户收到的评价
    INDEX idx_reviewee (revieweeId) COMMENT '被评价者索引 - 加速查询用户收到的评价',
    -- 任务索引：用于查询特定任务的评价
    INDEX idx_task (taskId) COMMENT '任务索引 - 加速查询特定任务的评价'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评价表 - 存储用户之间的评价信息，用于计算用户信誉分和信用管理';

-- ========================================
-- 第三步：创建数据库视图
-- ========================================
-- 视图的作用：简化复杂查询，提供常用的数据视图，提高查询效率

-- 创建视图：已接任务视图 (View_ReceivedTasks)
-- 功能：提供已接取任务的完整信息，包括任务详情、发布者信息、接单者信息
-- 使用场景：查看已接任务列表、任务详情展示、接单管理
CREATE OR REPLACE VIEW View_ReceivedTasks AS
SELECT 
    -- 任务基本信息
    t.tid,                    -- 任务ID
    t.publisherId,            -- 发布者ID
    t.company,                -- 快递公司
    t.pickupPlace,            -- 取件地点
    t.code,                   -- 取件码
    t.reward,                 -- 酬金
    t.deadline,               -- 截止时间
    t.status as taskStatus,   -- 任务状态
    t.createTime,             -- 任务创建时间
    
    -- 发布者信息
    u.username as publisherName,    -- 发布者用户名
    u.phone as publisherPhone,      -- 发布者手机号
    
    -- 接单记录信息
    ta.assignmentId,          -- 接单记录ID
    ta.takerId,               -- 接单者ID
    ta.acceptTime,            -- 接单时间
    ta.status as assignmentStatus,  -- 接单状态
    
    -- 接单者信息
    taker.username as takerName,    -- 接单者用户名
    taker.phone as takerPhone       -- 接单者手机号
FROM DeliveryTask t
-- 关联发布者信息
JOIN User u ON t.publisherId = u.uid
-- 关联接单记录
JOIN TaskAssignment ta ON t.tid = ta.taskId
-- 关联接单者信息
JOIN User taker ON ta.takerId = taker.uid;

-- 创建视图：待接任务视图 (View_AvailableTasks)
-- 功能：提供可接取任务的完整信息，只显示状态为待接单且未过期的任务
-- 使用场景：任务列表展示、接单页面、任务筛选
CREATE OR REPLACE VIEW View_AvailableTasks AS
SELECT 
    -- 任务基本信息
    t.tid,                    -- 任务ID
    t.publisherId,            -- 发布者ID
    t.company,                -- 快递公司
    t.pickupPlace,            -- 取件地点
    t.code,                   -- 取件码
    t.reward,                 -- 酬金
    t.deadline,               -- 截止时间
    t.status,                 -- 任务状态
    t.createTime,             -- 任务创建时间
    
    -- 发布者信息
    u.username as publisherName,        -- 发布者用户名
    u.reputation as publisherReputation -- 发布者信誉分
FROM DeliveryTask t
-- 关联发布者信息
JOIN User u ON t.publisherId = u.uid
-- 只显示待接单且未过期的任务
WHERE t.status = 'pending' AND t.deadline > NOW();

-- 创建视图：用户评价统计视图 (View_UserRatingStats)
-- 功能：提供用户评价的统计信息，包括总评价数、平均分、好评数、差评数
-- 使用场景：用户信誉展示、评价统计、用户信用分析
CREATE OR REPLACE VIEW View_UserRatingStats AS
SELECT 
    -- 用户基本信息
    u.uid,                    -- 用户ID
    u.username,               -- 用户名
    u.reputation,             -- 当前信誉分
    
    -- 评价统计信息
    COUNT(r.rid) as totalRatings,                    -- 总评价数
    AVG(r.score) as avgScore,                        -- 平均评分
    COUNT(CASE WHEN r.score >= 4 THEN 1 END) as goodRatings,  -- 好评数(4-5分)
    COUNT(CASE WHEN r.score <= 2 THEN 1 END) as badRatings    -- 差评数(1-2分)
FROM User u
-- 左连接评价表，确保没有评价的用户也会被包含
LEFT JOIN Rating r ON u.uid = r.revieweeId
-- 按用户分组
GROUP BY u.uid, u.username, u.reputation;

-- ========================================
-- 第四步：创建存储过程
-- ========================================
-- 存储过程的作用：封装复杂的业务逻辑，确保数据一致性，提高执行效率

-- 存储过程：接单功能 (AcceptTask)
-- 功能：处理用户接取任务的完整流程，包括状态检查和数据更新
-- 参数：p_takerId - 接单者ID, p_taskId - 任务ID
-- 业务逻辑：检查任务状态 -> 验证权限 -> 更新任务状态 -> 创建接单记录
DELIMITER //
CREATE PROCEDURE AcceptTask(IN p_takerId INT, IN p_taskId INT)
BEGIN
    -- 声明局部变量
    DECLARE v_taskStatus VARCHAR(20);    -- 任务状态
    DECLARE v_publisherId INT;           -- 发布者ID
    DECLARE v_reward DECIMAL(8,2);       -- 任务酬金
    
    -- 异常处理：如果发生错误，回滚事务并重新抛出异常
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- 回滚事务
        RESIGNAL;  -- 重新抛出异常
    END;
    
    -- 开始事务，确保数据一致性
    START TRANSACTION;
    
    -- 检查任务是否存在且状态为待接单，同时检查是否未过期
    -- 使用 FOR UPDATE 锁定记录，防止并发问题
    SELECT status, publisherId, reward INTO v_taskStatus, v_publisherId, v_reward
    FROM DeliveryTask 
    WHERE tid = p_taskId AND status = 'pending' AND deadline > NOW()
    FOR UPDATE;
    
    -- 如果任务不存在或已被接取，抛出异常
    IF v_taskStatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务不存在或已被接取';
    END IF;
    
    -- 检查是否是自己发布的任务，防止自己接自己的任务
    IF v_publisherId = p_takerId THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '不能接取自己发布的任务';
    END IF;
    
    -- 更新任务状态为已接单
    UPDATE DeliveryTask SET status = 'accepted' WHERE tid = p_taskId;
    
    -- 创建接单记录，状态默认为进行中
    INSERT INTO TaskAssignment (taskId, takerId, status) VALUES (p_taskId, p_takerId, 'in_progress');
    
    -- 提交事务
    COMMIT;
    
    -- 返回成功消息
    SELECT '接单成功' as message;
END //
DELIMITER ;

-- 存储过程：完成任务 (CompleteTask)
-- 功能：处理任务完成的完整流程，包括状态检查和数据更新
-- 参数：p_taskId - 任务ID, p_takerId - 接单者ID
-- 业务逻辑：验证接单记录 -> 更新任务状态 -> 更新接单记录 -> 记录完成时间
DELIMITER //
CREATE PROCEDURE CompleteTask(IN p_taskId INT, IN p_takerId INT)
BEGIN
    -- 声明局部变量
    DECLARE v_assignmentId INT;          -- 接单记录ID
    DECLARE v_publisherId INT;           -- 发布者ID
    DECLARE v_reward DECIMAL(8,2);       -- 任务酬金
    
    -- 异常处理：如果发生错误，回滚事务并重新抛出异常
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- 回滚事务
        RESIGNAL;  -- 重新抛出异常
    END;
    
    -- 开始事务，确保数据一致性
    START TRANSACTION;
    
    -- 检查任务记录是否存在且状态为进行中
    -- 使用 FOR UPDATE 锁定记录，防止并发问题
    SELECT ta.assignmentId, dt.publisherId, dt.reward INTO v_assignmentId, v_publisherId, v_reward
    FROM TaskAssignment ta
    JOIN DeliveryTask dt ON ta.taskId = dt.tid
    WHERE ta.taskId = p_taskId AND ta.takerId = p_takerId AND ta.status = 'in_progress'
    FOR UPDATE;
    
    -- 如果任务记录不存在或状态不正确，抛出异常
    IF v_assignmentId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
    END IF;
    
    -- 更新任务状态为已完成
    UPDATE DeliveryTask SET status = 'completed' WHERE tid = p_taskId;
    
    -- 更新接单记录状态为已完成，并记录完成时间
    UPDATE TaskAssignment SET status = 'completed', finishTime = NOW() WHERE assignmentId = v_assignmentId;
    
    -- 提交事务
    COMMIT;
    
    -- 返回成功消息
    SELECT '任务完成' as message;
END //
DELIMITER ;

-- 存储过程：取消任务 (CancelTask)
-- 功能：处理任务取消的完整流程，支持发布者和接单者取消
-- 参数：p_taskId - 任务ID, p_userId - 用户ID, p_userType - 用户类型(publisher/taker)
-- 业务逻辑：验证权限 -> 根据用户类型执行不同的取消逻辑
DELIMITER //
CREATE PROCEDURE CancelTask(IN p_taskId INT, IN p_userId INT, IN p_userType ENUM('publisher', 'taker'))
BEGIN
    -- 声明局部变量
    DECLARE v_assignmentId INT;          -- 接单记录ID
    DECLARE v_takerId INT;               -- 接单者ID
    DECLARE v_publisherId INT;           -- 发布者ID
    
    -- 异常处理：如果发生错误，回滚事务并重新抛出异常
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- 回滚事务
        RESIGNAL;  -- 重新抛出异常
    END;
    
    -- 开始事务，确保数据一致性
    START TRANSACTION;
    
    -- 根据用户类型执行不同的取消逻辑
    IF p_userType = 'publisher' THEN
        -- 发布者取消任务：需要验证发布者身份，任务状态变为已取消
        SELECT ta.assignmentId, ta.takerId INTO v_assignmentId, v_takerId
        FROM TaskAssignment ta
        JOIN DeliveryTask dt ON ta.taskId = dt.tid
        WHERE dt.tid = p_taskId AND dt.publisherId = p_userId AND ta.status = 'in_progress'
        FOR UPDATE;
        
        -- 如果任务记录不存在或状态不正确，抛出异常
        IF v_assignmentId IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
        END IF;
        
        -- 更新任务状态为已取消
        UPDATE DeliveryTask SET status = 'cancelled' WHERE tid = p_taskId;
        
        -- 更新接单记录状态为已取消
        UPDATE TaskAssignment SET status = 'cancelled' WHERE assignmentId = v_assignmentId;
        
    ELSE
        -- 接单者取消任务：任务状态恢复为待接单，删除接单记录
        SELECT ta.assignmentId, dt.publisherId INTO v_assignmentId, v_publisherId
        FROM TaskAssignment ta
        JOIN DeliveryTask dt ON ta.taskId = dt.tid
        WHERE ta.taskId = p_taskId AND ta.takerId = p_userId AND ta.status = 'in_progress'
        FOR UPDATE;
        
        -- 如果任务记录不存在或状态不正确，抛出异常
        IF v_assignmentId IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '任务记录不存在或状态不正确';
        END IF;
        
        -- 更新任务状态为待接单（恢复原状态）
        UPDATE DeliveryTask SET status = 'pending' WHERE tid = p_taskId;
        
        -- 删除接单记录（因为接单者取消，相当于从未接单）
        DELETE FROM TaskAssignment WHERE assignmentId = v_assignmentId;
    END IF;
    
    -- 提交事务
    COMMIT;
    
    -- 返回成功消息
    SELECT '任务取消成功' as message;
END //
DELIMITER ;

-- 存储过程：添加评价并更新信誉分 (AddRating)
-- 功能：处理评价添加和信誉分更新的完整流程
-- 参数：p_reviewerId - 评价者ID, p_revieweeId - 被评价者ID, p_taskId - 任务ID, p_score - 评分, p_comment - 评论
-- 业务逻辑：验证评分范围 -> 添加评价 -> 重新计算信誉分 -> 更新用户信誉分
DELIMITER //
CREATE PROCEDURE AddRating(
    IN p_reviewerId INT,      -- 评价者ID
    IN p_revieweeId INT,      -- 被评价者ID
    IN p_taskId INT,          -- 任务ID
    IN p_score TINYINT,       -- 评分
    IN p_comment TEXT         -- 评论
)
BEGIN
    -- 声明局部变量
    DECLARE v_avgScore DECIMAL(3,1);    -- 平均评分
    
    -- 异常处理：如果发生错误，回滚事务并重新抛出异常
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- 回滚事务
        RESIGNAL;  -- 重新抛出异常
    END;
    
    -- 开始事务，确保数据一致性
    START TRANSACTION;
    
    -- 检查评分范围，确保在1-5之间
    IF p_score < 1 OR p_score > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '评分必须在1-5之间';
    END IF;
    
    -- 添加评价记录
    INSERT INTO Rating (reviewerId, revieweeId, taskId, score, comment) 
    VALUES (p_reviewerId, p_revieweeId, p_taskId, p_score, p_comment);
    
    -- 计算被评价者的新的平均信誉分
    SELECT AVG(score) INTO v_avgScore
    FROM Rating 
    WHERE revieweeId = p_revieweeId;
    
    -- 更新用户信誉分
    UPDATE User SET reputation = v_avgScore WHERE uid = p_revieweeId;
    
    -- 提交事务
    COMMIT;
    
    -- 返回成功消息
    SELECT '评价添加成功' as message;
END //
DELIMITER ;

-- ========================================
-- 第五步：插入测试数据
-- ========================================
-- 测试数据的作用：提供系统演示和测试的基础数据，帮助用户快速了解系统功能

-- 插入测试用户数据
-- 注意：这些密码是 'password123' 的bcrypt加密版本，实际使用时应该使用更安全的密码
-- 测试用户包括不同信誉分的用户，用于演示评价系统
INSERT INTO User (username, password, email, phone, reputation) VALUES
-- 用户1：张三，信誉分5.0（默认信誉分）
('zhangsan', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'zhangsan@example.com', '13800138001', 5.0),
-- 用户2：李四，信誉分4.8（较高信誉分）
('lisi', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'lisi@example.com', '13800138002', 4.8),
-- 用户3：王五，信誉分4.5（中等信誉分）
('wangwu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'wangwu@example.com', '13800138003', 4.5),
-- 用户4：赵六，信誉分4.2（较低信誉分）
('zhaoliu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'zhaoliu@example.com', '13800138004', 4.2);

-- 插入测试任务数据
-- 测试任务包括不同快递公司、不同酬金、不同截止时间的任务
-- 所有任务状态均为待接单，用于演示接单功能
INSERT INTO DeliveryTask (publisherId, company, pickupPlace, code, reward, deadline, status) VALUES
-- 任务1：顺丰快递，第一教学楼快递点，酬金5元，2天后截止
(1, '顺丰快递', '第一教学楼快递点', 'SF123456', 5.00, DATE_ADD(NOW(), INTERVAL 2 DAY), 'pending'),
-- 任务2：圆通快递，图书馆快递柜，酬金8元，1天后截止
(2, '圆通快递', '图书馆快递柜', 'YT789012', 8.00, DATE_ADD(NOW(), INTERVAL 1 DAY), 'pending'),
-- 任务3：中通快递，学生公寓快递点，酬金6元，3天后截止
(3, '中通快递', '学生公寓快递点', 'ZT345678', 6.00, DATE_ADD(NOW(), INTERVAL 3 DAY), 'pending'),
-- 任务4：申通快递，食堂快递点，酬金7元，1天后截止
(1, '申通快递', '食堂快递点', 'ST901234', 7.00, DATE_ADD(NOW(), INTERVAL 1 DAY), 'pending');

-- ========================================
-- 第六步：显示初始化完成消息
-- ========================================
-- 确认数据库初始化成功，提供用户反馈
SELECT '数据库初始化完成！' as message; 

-- ========================================
-- 数据库初始化脚本执行完成
-- ========================================
-- 
-- 脚本执行后的验证步骤：
-- 1. 检查表是否创建成功：SHOW TABLES;
-- 2. 检查视图是否创建成功：SHOW FULL TABLES WHERE Table_type = 'VIEW';
-- 3. 检查存储过程是否创建成功：SHOW PROCEDURE STATUS WHERE Db = 'express_delivery_system';
-- 4. 检查测试数据是否插入成功：SELECT COUNT(*) FROM User; SELECT COUNT(*) FROM DeliveryTask;
-- 
-- 系统使用说明：
-- 1. 用户注册和登录：使用测试账号或注册新账号
-- 2. 发布任务：在"发布任务"页面创建新的快递代取任务
-- 3. 接取任务：在"任务列表"页面查看和接取可用任务
-- 4. 完成任务：在"我的任务"页面管理已接取的任务
-- 5. 评价系统：任务完成后可以对对方进行评价
-- 
-- 注意事项：
-- 1. 本脚本可以重复执行，不会产生重复数据
-- 2. 测试数据仅用于演示，生产环境请删除或修改
-- 3. 密码加密使用bcrypt算法，确保安全性
-- 4. 所有时间字段使用UTC时间，注意时区设置
-- ======================================== 