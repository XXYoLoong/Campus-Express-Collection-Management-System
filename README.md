# 学校快递任务代取管理系统
# Campus Express Collection Management System

## 项目简介
学校快递任务代取管理系统是一套面向校园学生和工作者的基于 MySQL 数据库的互动系统，为学校快递任务管理提供数据支撑。

## 技术栈
- 后端：Node.js + Express + MySQL
- 前端：HTML + CSS + JavaScript
- 数据库：MySQL 8.0+

## 项目结构
```
快递代取/
├── database/          # 数据库脚本
├── backend/           # 后端API
├── frontend/          # 前端界面
├── run.bat            # 统一启动脚本 (推荐)
├── package.json       # 项目配置
└── README.md         # 项目说明
```

## 功能模块
- 用户注册/登录
- 发布任务
- 查看待接任务列表
- 接单功能
- 完成/取消任务
- 评价系统
- 信誉分管理

## 快速开始

### 🚀 一键启动 (推荐)

#### Windows用户
```bash
# 双击运行统一启动脚本
run.bat
```

然后选择：
- **选项5**: 一键安装并启动 (推荐首次使用)
- **选项1-4**: 分步执行 (适合调试)

#### Linux/Mac用户
```bash
# 给脚本执行权限
chmod +x setup.sh start.sh

# 运行安装脚本
./setup.sh

# 启动系统
./start.sh
```

### 📋 统一启动脚本功能

`run.bat` 提供以下功能：

1. **环境检查** - 检查Node.js、项目文件、MySQL
2. **安装依赖** - 安装后端npm依赖
3. **数据库配置** - 配置MySQL连接和初始化数据库
4. **启动系统** - 启动后端服务并打开浏览器
5. **一键安装并启动** - 自动执行所有步骤 (推荐)
6. **退出** - 安全退出程序

### 🔒 安全特性

- **密码不保存**: 每次运行时用户手动输入MySQL密码
- **临时使用**: 密码仅在当前会话中使用，不会保存到文件
- **安全输入**: 使用PowerShell隐藏密码输入

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

#### 查看数据
```sql
-- 查看用户
SELECT * FROM User;

-- 查看任务
SELECT * FROM DeliveryTask;

-- 查看接单记录
SELECT * FROM TaskAssignment;

-- 查看评价
SELECT * FROM Rating;
```

#### 常用查询
```sql
-- 查看活跃用户
SELECT username, task_count, total_earnings 
FROM UserStats 
ORDER BY task_count DESC;

-- 查看任务统计
SELECT status, COUNT(*) as count 
FROM DeliveryTask 
GROUP BY status;

-- 查看用户评价
SELECT u.username, r.rating, r.comment, r.created_at
FROM Rating r
JOIN User u ON r.rated_user_id = u.id
ORDER BY r.created_at DESC;
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
- **User表**: 用户信息
- **DeliveryTask表**: 快递任务
- **TaskAssignment表**: 任务接取记录
- **Rating表**: 评价信息
- **UserStats视图**: 用户统计信息

### 开发模式
```bash
cd backend
npm run dev  # 自动重启模式
```

### 测试数据
系统初始化时会创建4个测试用户和示例任务，可以直接使用进行功能测试。

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

**注意**: 这是一个教学演示项目，生产环境使用前请进行充分的安全测试和性能优化。 