# 学校快递任务代取管理系统
# Campus Express Collection Management System

一个基于MySQL数据库的学校快递任务代取管理系统，支持用户注册登录、发布任务、接单、完成任务和评价功能。

## 功能特性

- 👤 **用户管理**: 用户注册、登录、个人信息管理
- 📦 **任务管理**: 发布快递代取任务、查看任务列表、接单、完成任务
- ⭐ **评价系统**: 对完成的任务进行评价和查看
- 💰 **积分系统**: 任务完成获得积分奖励
- 📊 **数据统计**: 任务统计、用户活跃度分析
- 🔒 **安全认证**: JWT token认证、密码加密存储

## 系统架构

```
快递代取/
├── backend/          # 后端服务 (Node.js + Express)
│   ├── config/       # 配置文件
│   ├── middleware/   # 中间件
│   ├── routes/       # 路由模块
│   └── server.js     # 服务器入口
├── database/         # 数据库脚本
│   └── init.sql      # 数据库初始化脚本
├── frontend/         # 前端界面 (HTML + CSS + JS)
│   ├── index.html    # 主页面
│   ├── styles.css    # 样式文件
│   └── script.js     # 前端逻辑
├── run.bat           # Windows统一启动脚本 (推荐)
├── run.sh            # Linux/Mac统一启动脚本
└── README.md         # 项目说明
```

## 快速开始

### 🚀 一键启动 (推荐)

#### Windows用户
```bash
# 双击运行统一启动脚本
run.bat
```

#### Linux/Mac用户
```bash
# 给脚本添加执行权限
chmod +x run.sh

# 运行统一启动脚本
./run.sh
```

然后按照菜单提示选择：
1. **环境检查** - 检查Node.js、MySQL等环境
2. **安装依赖** - 安装后端依赖包
3. **数据库初始化** - 初始化数据库和表结构
4. **启动系统** - 启动后端服务并打开浏览器
5. **一键完整安装并启动** - 自动执行所有步骤

### 手动安装

#### 1. 环境要求
- Node.js 14.0+
- MySQL 8.0+
- npm 6.0+

#### 2. 安装依赖
```bash
# 安装后端依赖
cd backend
npm install
cd ..
```

#### 3. 数据库配置
```bash
# 连接MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE express_delivery_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 退出MySQL
exit

# 初始化数据库
mysql -u root -p express_delivery_system < database/init.sql
```

#### 4. 启动服务
```bash
# 启动后端服务
cd backend
npm start

# 新开终端，访问前端
# 浏览器打开 http://localhost:3000
```

## 使用说明

### 默认测试账号
- 用户名: 张三, 密码: password123
- 用户名: 李四, 密码: password123  
- 用户名: 王五, 密码: password123
- 用户名: 赵六, 密码: password123

### 主要功能

#### 1. 用户管理
- 注册新用户
- 用户登录/登出
- 查看个人信息
- 修改密码

#### 2. 任务管理
- 发布快递代取任务
- 查看所有可用任务
- 接取任务
- 完成任务
- 取消任务

#### 3. 评价系统
- 对完成的任务进行评价
- 查看任务评价
- 用户评分统计

### 数据库操作

#### 连接数据库
```sql
mysql -u root -p express_delivery_system
```

#### 查看数据库结构
```sql
-- 查看所有表
SHOW TABLES;

-- 查看表结构
DESCRIBE User;
DESCRIBE DeliveryTask;
DESCRIBE TaskAssignment;
DESCRIBE Rating;

-- 查看表的详细结构
SHOW CREATE TABLE User;
SHOW CREATE TABLE DeliveryTask;
SHOW CREATE TABLE TaskAssignment;
SHOW CREATE TABLE Rating;

-- 查看所有视图
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 查看存储过程
SHOW PROCEDURE STATUS WHERE Db = 'express_delivery_system';

-- 查看触发器
SHOW TRIGGERS;
```

#### 查看所有数据
```sql
-- 查看用户表所有数据
SELECT * FROM User;

-- 查看任务表所有数据
SELECT * FROM DeliveryTask;

-- 查看接单记录表所有数据
SELECT * FROM TaskAssignment;

-- 查看评价表所有数据
SELECT * FROM Rating;

-- 查看用户评价统计视图
SELECT * FROM View_UserRatingStats;

-- 查看可用任务视图
SELECT * FROM View_AvailableTasks;

-- 查看已接任务视图
SELECT * FROM View_ReceivedTasks;
```

#### 常用查询语句
```sql
-- 查看用户数量
SELECT COUNT(*) as user_count FROM User;

-- 查看任务数量
SELECT COUNT(*) as task_count FROM DeliveryTask;

-- 查看各状态任务数量
SELECT status, COUNT(*) as count 
FROM DeliveryTask 
GROUP BY status;

-- 查看用户及其发布的任务数量
SELECT u.username, COUNT(d.tid) as published_tasks
FROM User u
LEFT JOIN DeliveryTask d ON u.uid = d.publisherId
GROUP BY u.uid, u.username
ORDER BY published_tasks DESC;

-- 查看用户及其接取的任务数量
SELECT u.username, COUNT(ta.taskId) as accepted_tasks
FROM User u
LEFT JOIN TaskAssignment ta ON u.uid = ta.takerId
GROUP BY u.uid, u.username
ORDER BY accepted_tasks DESC;

-- 查看任务详情（包含发布者和接取者信息）
SELECT 
    d.tid,
    d.company,
    d.pickupPlace,
    d.code,
    d.reward,
    d.status,
    d.deadline,
    d.createTime,
    publisher.username as publisher_name,
    taker.username as taker_name,
    ta.acceptTime
FROM DeliveryTask d
LEFT JOIN User publisher ON d.publisherId = publisher.uid
LEFT JOIN TaskAssignment ta ON d.tid = ta.taskId
LEFT JOIN User taker ON ta.takerId = taker.uid
ORDER BY d.createTime DESC;

-- 查看评价详情（包含评价者和被评价者信息）
SELECT 
    r.rid,
    r.score,
    r.comment,
    r.createTime,
    reviewer.username as reviewer_name,
    reviewee.username as reviewee_name,
    d.company as task_company
FROM Rating r
JOIN User reviewer ON r.reviewerId = reviewer.uid
JOIN User reviewee ON r.revieweeId = reviewee.uid
JOIN DeliveryTask d ON r.taskId = d.tid
ORDER BY r.createTime DESC;

-- 查看用户信誉分排名
SELECT username, reputation, 
       (SELECT COUNT(*) FROM DeliveryTask WHERE publisherId = u.uid) as published_count,
       (SELECT COUNT(*) FROM TaskAssignment WHERE takerId = u.uid) as accepted_count
FROM User u
ORDER BY reputation DESC;

-- 查看任务完成率
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM DeliveryTask), 2) as percentage
FROM DeliveryTask 
GROUP BY status;

-- 查看平均评价分数
SELECT 
    u.username,
    AVG(r.score) as avg_score,
    COUNT(r.rid) as rating_count
FROM User u
LEFT JOIN Rating r ON u.uid = r.revieweeId
GROUP BY u.uid, u.username
HAVING rating_count > 0
ORDER BY avg_score DESC;
```

#### 数据统计查询
```sql
-- 系统总体统计
SELECT 
    (SELECT COUNT(*) FROM User) as total_users,
    (SELECT COUNT(*) FROM DeliveryTask) as total_tasks,
    (SELECT COUNT(*) FROM TaskAssignment) as total_assignments,
    (SELECT COUNT(*) FROM Rating) as total_ratings,
    (SELECT AVG(reputation) FROM User) as avg_reputation,
    (SELECT AVG(reward) FROM DeliveryTask) as avg_reward;

-- 每日任务发布统计
SELECT 
    DATE(createTime) as date,
    COUNT(*) as task_count,
    SUM(reward) as total_reward
FROM DeliveryTask
GROUP BY DATE(createTime)
ORDER BY date DESC
LIMIT 30;

-- 快递公司任务分布
SELECT 
    company,
    COUNT(*) as task_count,
    AVG(reward) as avg_reward,
    SUM(reward) as total_reward
FROM DeliveryTask
GROUP BY company
ORDER BY task_count DESC;

-- 用户活跃度统计
SELECT 
    u.username,
    (SELECT COUNT(*) FROM DeliveryTask WHERE publisherId = u.uid) as published_tasks,
    (SELECT COUNT(*) FROM TaskAssignment WHERE takerId = u.uid) as accepted_tasks,
    (SELECT COUNT(*) FROM Rating WHERE reviewerId = u.uid) as given_ratings,
    (SELECT COUNT(*) FROM Rating WHERE revieweeId = u.uid) as received_ratings,
    u.reputation
FROM User u
ORDER BY (published_tasks + accepted_tasks) DESC;
```

#### 数据清理和维护
```sql
-- 查看过期任务
SELECT * FROM DeliveryTask 
WHERE deadline < NOW() AND status = 'pending';

-- 查看长时间未完成的任务
SELECT * FROM DeliveryTask 
WHERE status = 'accepted' 
AND createTime < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 查看用户注册时间
SELECT username, createTime 
FROM User 
ORDER BY createTime DESC;

-- 查看最近的活动
SELECT 'Task Created' as activity, createTime as time, tid as id
FROM DeliveryTask
UNION ALL
SELECT 'Task Accepted' as activity, acceptTime as time, taskId as id
FROM TaskAssignment
UNION ALL
SELECT 'Rating Added' as activity, createTime as time, rid as id
FROM Rating
ORDER BY time DESC
LIMIT 20;
```

## 数据库管理

### 数据库备份和恢复

#### 备份数据库
```bash
# 备份整个数据库
mysqldump -u root -p express_delivery_system > backup_$(date +%Y%m%d_%H%M%S).sql

# 备份特定表
mysqldump -u root -p express_delivery_system User DeliveryTask > tables_backup.sql

# 备份结构和数据
mysqldump -u root -p --routines --triggers express_delivery_system > full_backup.sql
```

#### 恢复数据库
```bash
# 恢复整个数据库
mysql -u root -p express_delivery_system < backup_file.sql

# 恢复特定表
mysql -u root -p express_delivery_system < tables_backup.sql
```

### 数据库性能优化

#### 查看表大小
```sql
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
    table_rows
FROM information_schema.tables 
WHERE table_schema = 'express_delivery_system'
ORDER BY (data_length + index_length) DESC;
```

#### 查看索引使用情况
```sql
SELECT 
    table_name,
    index_name,
    cardinality
FROM information_schema.statistics 
WHERE table_schema = 'express_delivery_system'
ORDER BY table_name, index_name;
```

#### 优化表
```sql
-- 分析表
ANALYZE TABLE User, DeliveryTask, TaskAssignment, Rating;

-- 优化表
OPTIMIZE TABLE User, DeliveryTask, TaskAssignment, Rating;

-- 检查表
CHECK TABLE User, DeliveryTask, TaskAssignment, Rating;
```

### 数据库监控

#### 查看连接状态
```sql
-- 查看当前连接
SHOW PROCESSLIST;

-- 查看连接数
SHOW STATUS LIKE 'Threads_connected';

-- 查看最大连接数
SHOW VARIABLES LIKE 'max_connections';
```

#### 查看查询性能
```sql
-- 启用慢查询日志
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- 查看慢查询
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;
```

### 数据导入导出

#### 导出数据为CSV
```sql
-- 导出用户数据
SELECT 'uid', 'username', 'email', 'phone', 'reputation', 'createTime'
UNION ALL
SELECT uid, username, email, phone, reputation, createTime
FROM User
INTO OUTFILE '/tmp/users.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- 导出任务数据
SELECT 'tid', 'publisherId', 'company', 'pickupPlace', 'code', 'reward', 'status', 'deadline', 'createTime'
UNION ALL
SELECT tid, publisherId, company, pickupPlace, code, reward, status, deadline, createTime
FROM DeliveryTask
INTO OUTFILE '/tmp/tasks.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

#### 导入CSV数据
```sql
-- 导入用户数据
LOAD DATA INFILE '/tmp/users.csv'
INTO TABLE User
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(uid, username, email, phone, reputation, createTime);
```

### 数据库安全

#### 用户权限管理
```sql
-- 创建只读用户
CREATE USER 'readonly'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT ON express_delivery_system.* TO 'readonly'@'localhost';

-- 创建应用用户
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON express_delivery_system.* TO 'app_user'@'localhost';

-- 查看用户权限
SHOW GRANTS FOR 'app_user'@'localhost';
```

#### 数据加密
```sql
-- 查看加密状态
SHOW VARIABLES LIKE 'have_ssl';

-- 启用SSL连接
ALTER USER 'root'@'localhost' REQUIRE SSL;
```

## API接口

### 认证接口
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/profile` - 获取用户信息

### 任务接口
- `GET /api/tasks` - 获取任务列表
- `POST /api/tasks` - 发布新任务
- `GET /api/tasks/:id` - 获取任务详情
- `PUT /api/tasks/:id/accept` - 接取任务
- `PUT /api/tasks/:id/complete` - 完成任务
- `PUT /api/tasks/:id/cancel` - 取消任务

### 评价接口
- `POST /api/ratings` - 发表评价
- `GET /api/ratings/user/:userId` - 获取用户评价
- `GET /api/ratings/task/:taskId` - 获取任务评价

## 开发指南

### 项目结构说明

#### 后端结构
```
backend/
├── config/
│   └── database.js    # 数据库配置
├── middleware/
│   └── auth.js        # JWT认证中间件
├── routes/
│   ├── auth.js        # 认证路由
│   ├── tasks.js       # 任务路由
│   └── ratings.js     # 评价路由
└── server.js          # 服务器入口
```

#### 数据库设计
- **User表**: 用户信息（uid, username, password, email, phone, reputation, createTime）
- **DeliveryTask表**: 快递任务（tid, publisherId, company, pickupPlace, code, reward, deadline, status, createTime）
- **TaskAssignment表**: 任务接取记录（assignmentId, taskId, takerId, acceptTime, finishTime, status）
- **Rating表**: 评价信息（rid, reviewerId, revieweeId, taskId, score, comment, createTime）
- **View_AvailableTasks视图**: 待接任务视图
- **View_ReceivedTasks视图**: 已接任务视图
- **View_UserRatingStats视图**: 用户评价统计视图
- **AcceptTask存储过程**: 接单功能
- **CompleteTask存储过程**: 完成任务功能
- **CancelTask存储过程**: 取消任务功能
- **AddRating存储过程**: 添加评价功能

### 开发模式
```bash
cd backend
npm run dev  # 自动重启模式
```

### 测试数据

系统初始化时会创建以下测试数据：

#### 测试用户
- 用户名: `zhangsan`, 密码: `password123`, 信誉分: 5.0
- 用户名: `lisi`, 密码: `password123`, 信誉分: 4.8
- 用户名: `wangwu`, 密码: `password123`, 信誉分: 4.5
- 用户名: `zhaoliu`, 密码: `password123`, 信誉分: 4.2

#### 测试任务
- 顺丰快递 - 第一教学楼快递点 (SF123456) - 5.00元
- 圆通快递 - 图书馆快递柜 (YT789012) - 8.00元
- 中通快递 - 学生公寓快递点 (ZT345678) - 6.00元
- 申通快递 - 食堂快递点 (ST901234) - 7.00元

#### 验证测试数据
```sql
-- 查看测试用户
SELECT username, email, phone, reputation FROM User;

-- 查看测试任务
SELECT company, pickupPlace, code, reward, status FROM DeliveryTask;

-- 查看任务状态分布
SELECT status, COUNT(*) as count FROM DeliveryTask GROUP BY status;
```

## 故障排除

### 常见问题

1. **端口被占用**
   - 修改 `backend/server.js` 中的端口号
   - 或关闭占用端口的程序

2. **数据库连接失败**
   - 检查MySQL服务是否启动
   - 确认用户名密码正确
   - 检查数据库是否存在

3. **依赖安装失败**
   - 删除 `backend/node_modules` 文件夹
   - 重新运行 `npm install`

4. **前端页面无法访问**
   - 确认后端服务已启动
   - 检查浏览器控制台错误信息
   - 确认端口号正确

### 日志查看
```bash
# 查看后端日志
cd backend
npm start

# 查看数据库日志
mysql -u root -p -e "SHOW PROCESSLIST;"
```

## 安全特性

### 🔒 密码安全
- **不保存密码**: 所有密码都是临时使用，不会保存在代码中
- **隐藏输入**: 使用PowerShell隐藏密码输入
- **临时配置**: 数据库配置仅在运行时临时创建

### 🛡️ 数据保护
- **JWT认证**: 使用JWT token进行用户认证
- **密码加密**: 使用bcrypt加密存储用户密码
- **SQL注入防护**: 使用参数化查询防止SQL注入

## 技术栈

- **后端**: Node.js + Express + MySQL
- **前端**: HTML5 + CSS3 + JavaScript (ES6+)
- **数据库**: MySQL 8.0+
- **认证**: JWT (JSON Web Token)
- **加密**: bcrypt
- **跨域**: CORS

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 联系方式

如有问题，请通过以下方式联系：
- 提交GitHub Issue
- 发送邮件至项目维护者

---

## 快速参考

### 🔍 常用数据库查询

#### 快速查看系统状态
```sql
-- 一键查看系统概况
SELECT 
    'Users' as type, COUNT(*) as count FROM User
UNION ALL
SELECT 'Tasks', COUNT(*) FROM DeliveryTask
UNION ALL
SELECT 'Assignments', COUNT(*) FROM TaskAssignment
UNION ALL
SELECT 'Ratings', COUNT(*) FROM Rating;
```

#### 查看最新活动
```sql
-- 最近10个活动
(SELECT 'Task Created' as activity, createTime as time, tid as id, company as detail
FROM DeliveryTask ORDER BY createTime DESC LIMIT 5)
UNION ALL
(SELECT 'Task Accepted', acceptTime, taskId, 'Accepted' as detail
FROM TaskAssignment ORDER BY acceptTime DESC LIMIT 3)
UNION ALL
(SELECT 'Rating Added', createTime, rid, CONCAT('Score: ', score) as detail
FROM Rating ORDER BY createTime DESC LIMIT 2)
ORDER BY time DESC LIMIT 10;
```

#### 查看热门用户
```sql
-- 最活跃的用户
SELECT 
    u.username,
    u.reputation,
    (SELECT COUNT(*) FROM DeliveryTask WHERE publisherId = u.uid) as published,
    (SELECT COUNT(*) FROM TaskAssignment WHERE takerId = u.uid) as accepted,
    (SELECT AVG(score) FROM Rating WHERE revieweeId = u.uid) as avg_rating
FROM User u
ORDER BY (published + accepted) DESC, u.reputation DESC
LIMIT 10;
```

### 🛠️ 常用维护命令

#### 数据库健康检查
```sql
-- 检查表状态
CHECK TABLE User, DeliveryTask, TaskAssignment, Rating;

-- 查看表大小
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'express_delivery_system';
```

#### 清理过期数据
```sql
-- 查看过期任务
SELECT COUNT(*) as expired_tasks 
FROM DeliveryTask 
WHERE deadline < NOW() AND status = 'pending';

-- 查看长时间未完成的任务
SELECT COUNT(*) as old_accepted_tasks
FROM DeliveryTask 
WHERE status = 'accepted' 
AND createTime < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

### 📊 数据统计查询

#### 系统统计面板
```sql
-- 系统总览
SELECT 
    (SELECT COUNT(*) FROM User) as total_users,
    (SELECT COUNT(*) FROM DeliveryTask WHERE status = 'pending') as pending_tasks,
    (SELECT COUNT(*) FROM DeliveryTask WHERE status = 'completed') as completed_tasks,
    (SELECT AVG(reward) FROM DeliveryTask) as avg_reward,
    (SELECT AVG(reputation) FROM User) as avg_reputation;
```

#### 任务分析
```sql
-- 任务完成率分析
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM DeliveryTask), 2) as percentage
FROM DeliveryTask 
GROUP BY status
ORDER BY count DESC;
```

### 🔧 故障排除查询

#### 检查数据完整性
```sql
-- 检查孤立的任务分配
SELECT ta.* FROM TaskAssignment ta
LEFT JOIN DeliveryTask d ON ta.taskId = d.tid
WHERE d.tid IS NULL;

-- 检查孤立的评价
SELECT r.* FROM Rating r
LEFT JOIN DeliveryTask d ON r.taskId = d.tid
WHERE d.tid IS NULL;
```

#### 检查用户活动
```sql
-- 查看最近注册的用户
SELECT username, createTime 
FROM User 
ORDER BY createTime DESC 
LIMIT 10;

-- 查看活跃任务
SELECT 
    d.tid,
    d.company,
    d.status,
    d.createTime,
    u.username as publisher
FROM DeliveryTask d
JOIN User u ON d.publisherId = u.uid
WHERE d.status IN ('pending', 'accepted')
ORDER BY d.createTime DESC;
```

---

**注意**: 这是一个教学演示项目，生产环境使用前请进行充分的安全测试和性能优化。

## 数据库设计

### 数据库表结构

#### 1. 用户表 (User)
```sql
CREATE TABLE User (
    uid INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    reputation DECIMAL(3,1) DEFAULT 5.0 COMMENT '信誉分',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间'
);
```

#### 2. 快递任务表 (DeliveryTask)
```sql
CREATE TABLE DeliveryTask (
    tid INT AUTO_INCREMENT PRIMARY KEY COMMENT '任务ID',
    publisherId INT NOT NULL COMMENT '发布者ID',
    company VARCHAR(50) NOT NULL COMMENT '快递公司',
    pickupPlace VARCHAR(200) NOT NULL COMMENT '取件地点',
    code VARCHAR(50) NOT NULL COMMENT '取件码',
    reward DECIMAL(8,2) NOT NULL COMMENT '酬金',
    deadline TIMESTAMP NOT NULL COMMENT '截止时间',
    status ENUM('pending', 'accepted', 'completed', 'cancelled') DEFAULT 'pending' COMMENT '任务状态',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    FOREIGN KEY (publisherId) REFERENCES User(uid) ON DELETE CASCADE
);
```

#### 3. 任务接取记录表 (TaskAssignment)
```sql
CREATE TABLE TaskAssignment (
    assignmentId INT AUTO_INCREMENT PRIMARY KEY COMMENT '接单记录ID',
    taskId INT NOT NULL UNIQUE COMMENT '任务ID',
    takerId INT NOT NULL COMMENT '接单者ID',
    acceptTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '接单时间',
    finishTime TIMESTAMP NULL COMMENT '完成时间',
    status ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress' COMMENT '状态',
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE,
    FOREIGN KEY (takerId) REFERENCES User(uid) ON DELETE CASCADE
);
```

#### 4. 评价表 (Rating)
```sql
CREATE TABLE Rating (
    rid INT AUTO_INCREMENT PRIMARY KEY COMMENT '评价ID',
    reviewerId INT NOT NULL COMMENT '评价者ID',
    revieweeId INT NOT NULL COMMENT '被评者ID',
    taskId INT NOT NULL COMMENT '来源任务ID',
    score TINYINT NOT NULL CHECK (score >= 1 AND score <= 5) COMMENT '分数(1-5)',
    comment TEXT COMMENT '评论',
    createTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '时间',
    FOREIGN KEY (reviewerId) REFERENCES User(uid) ON DELETE CASCADE,
    FOREIGN KEY (revieweeId) REFERENCES User(uid) ON DELETE CASCADE,
    FOREIGN KEY (taskId) REFERENCES DeliveryTask(tid) ON DELETE CASCADE
);
```

### 数据库视图

#### 1. 已接任务视图 (View_ReceivedTasks)
```sql
CREATE VIEW View_ReceivedTasks AS
SELECT 
    t.tid, t.company, t.pickupPlace, t.code, t.reward, t.deadline,
    t.status as taskStatus, t.createTime,
    u.username as publisherName, u.phone as publisherPhone,
    ta.assignmentId, ta.acceptTime, ta.status as assignmentStatus,
    taker.username as takerName, taker.phone as takerPhone
FROM DeliveryTask t
JOIN User u ON t.publisherId = u.uid
JOIN TaskAssignment ta ON t.tid = ta.taskId
JOIN User taker ON ta.takerId = taker.uid;
```

#### 2. 待接任务视图 (View_AvailableTasks)
```sql
CREATE VIEW View_AvailableTasks AS
SELECT 
    t.tid, t.company, t.pickupPlace, t.code, t.reward, t.deadline, t.createTime,
    u.username as publisherName, u.reputation as publisherReputation
FROM DeliveryTask t
JOIN User u ON t.publisherId = u.uid
WHERE t.status = 'pending' AND t.deadline > NOW();
```

#### 3. 用户评价统计视图 (View_UserRatingStats)
```sql
CREATE VIEW View_UserRatingStats AS
SELECT 
    u.uid, u.username, u.reputation,
    COUNT(r.rid) as totalRatings,
    AVG(r.score) as avgScore,
    COUNT(CASE WHEN r.score >= 4 THEN 1 END) as goodRatings,
    COUNT(CASE WHEN r.score <= 2 THEN 1 END) as badRatings
FROM User u
LEFT JOIN Rating r ON u.uid = r.revieweeId
GROUP BY u.uid, u.username, u.reputation;
```

### 存储过程

#### 1. 接单功能 (AcceptTask)
```sql
CALL AcceptTask(takerId, taskId);
-- 功能：接取指定任务，更新任务状态为accepted，创建接单记录
```

#### 2. 完成任务 (CompleteTask)
```sql
CALL CompleteTask(taskId, takerId);
-- 功能：完成指定任务，更新任务状态为completed，更新接单记录
```

#### 3. 取消任务 (CancelTask)
```sql
CALL CancelTask(taskId, userId, userType);
-- 功能：取消任务，userType可以是'publisher'或'taker'
```

#### 4. 添加评价 (AddRating)
```sql
CALL AddRating(reviewerId, revieweeId, taskId, score, comment);
-- 功能：添加评价并自动更新用户信誉分
```

### 状态说明

#### 任务状态 (DeliveryTask.status)
- `pending` - 待接单
- `accepted` - 已接单
- `completed` - 已完成
- `cancelled` - 已取消

#### 接单状态 (TaskAssignment.status)
- `in_progress` - 进行中
- `completed` - 已完成
- `cancelled` - 已取消 