const express = require('express');
const cors = require('cors');
const path = require('path');
const { exec } = require('child_process');
const net = require('net');
require('dotenv').config();

const { testConnection } = require('./config/database');

// 路由导入
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const ratingRoutes = require('./routes/ratings');

const app = express();
const DEFAULT_PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件服务
app.use(express.static(path.join(__dirname, '../frontend')));

// API路由
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/ratings', ratingRoutes);

// 健康检查
app.get('/api/health', (req, res) => {
    res.json({ 
        message: '服务器运行正常',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// 前端路由处理
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error('服务器错误：', err);
    res.status(500).json({ message: '服务器内部错误' });
});

// 检查端口是否可用
function isPortAvailable(port) {
    return new Promise((resolve) => {
        const server = net.createServer();
        
        server.listen(port, () => {
            server.once('close', () => {
                resolve(true);
            });
            server.close();
        });
        
        server.on('error', () => {
            resolve(false);
        });
    });
}

// 查找可用端口
async function findAvailablePort(startPort) {
    let port = startPort;
    while (!(await isPortAvailable(port))) {
        port++;
        if (port > startPort + 100) {
            throw new Error('无法找到可用端口');
        }
    }
    return port;
}

// 打开浏览器函数
function openBrowser(url) {
    const platform = process.platform;
    let command;
    
    switch (platform) {
        case 'win32':
            command = `start ${url}`;
            break;
        case 'darwin':
            command = `open ${url}`;
            break;
        default:
            command = `xdg-open ${url}`;
            break;
    }
    
    exec(command, (error) => {
        if (error) {
            console.log('无法自动打开浏览器，请手动访问:', url);
        } else {
            console.log('浏览器已自动打开:', url);
        }
    });
}

// 启动服务器
async function startServer() {
    try {
        // 测试数据库连接
        await testConnection();
        
        // 查找可用端口
        const port = await findAvailablePort(DEFAULT_PORT);
        
        app.listen(port, () => {
            console.log(`服务器运行在端口 ${port}`);
            console.log(`前端地址: http://localhost:${port}`);
            console.log(`API地址: http://localhost:${port}/api`);
            
            if (port !== DEFAULT_PORT) {
                console.log(`注意：端口 ${DEFAULT_PORT} 被占用，已自动切换到端口 ${port}`);
            }
            
            // 等待2秒后打开浏览器，确保服务器完全启动
            setTimeout(() => {
                openBrowser(`http://localhost:${port}`);
            }, 2000);
        });
    } catch (error) {
        console.error('启动服务器失败：', error);
        process.exit(1);
    }
}

startServer(); 