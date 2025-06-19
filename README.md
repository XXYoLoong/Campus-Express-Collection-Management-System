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

**注意**: 这是一个教学演示项目，生产环境使用前请进行充分的安全测试和性能优化。 