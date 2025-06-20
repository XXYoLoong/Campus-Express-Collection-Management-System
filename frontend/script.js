// 全局变量
let currentUser = null;
let currentTaskId = null;
let currentRevieweeId = null;

// API基础URL
const API_BASE = '/api';

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

// 初始化应用
function initializeApp() {
    // 检查用户登录状态
    checkAuthStatus();
    
    // 绑定事件监听器
    bindEventListeners();
    
    // 设置默认截止时间（24小时后）
    setDefaultDeadline();
}

// 检查用户认证状态
function checkAuthStatus() {
    const token = localStorage.getItem('token');
    if (token) {
        // 验证token有效性
        fetch(`${API_BASE}/auth/profile`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        })
        .then(response => {
            if (response.ok) {
                return response.json();
            } else if (response.status === 401 || response.status === 403) {
                // Token无效，清除并重新登录
                console.log('Token无效，需要重新登录');
                localStorage.removeItem('token');
                currentUser = null;
                updateUIForLoggedOutUser();
                showMessage('登录已过期，请重新登录', 'warning');
                return null;
            } else {
                throw new Error('Token验证失败');
            }
        })
        .then(data => {
            if (data) {
                currentUser = data.user;
                updateUIForLoggedInUser();
            }
        })
        .catch(error => {
            console.error('Token验证失败:', error);
            localStorage.removeItem('token');
            currentUser = null;
            updateUIForLoggedOutUser();
            showMessage('登录状态异常，请重新登录', 'warning');
        });
    } else {
        updateUIForLoggedOutUser();
    }
}

// 绑定事件监听器
function bindEventListeners() {
    // 导航链接
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const page = this.getAttribute('data-page');
            showPage(page);
        });
    });

    // 登录按钮
    document.getElementById('loginBtn').addEventListener('click', function() {
        showModal('loginModal');
    });

    // 注册按钮
    document.getElementById('registerBtn').addEventListener('click', function() {
        showModal('registerModal');
    });

    // 退出按钮
    document.getElementById('logoutBtn').addEventListener('click', function() {
        logout();
    });

    // 清除缓存按钮（如果存在）
    const clearCacheBtn = document.getElementById('clearCacheBtn');
    if (clearCacheBtn) {
        clearCacheBtn.addEventListener('click', function() {
            if (confirm('确定要清除缓存并重新登录吗？')) {
                clearCacheAndReload();
            }
        });
    }

    // 移动端菜单切换
    document.getElementById('navToggle').addEventListener('click', function() {
        document.getElementById('navMenu').classList.toggle('active');
    });

    // 表单提交事件
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    document.getElementById('registerForm').addEventListener('submit', handleRegister);
    document.getElementById('publishForm').addEventListener('submit', handlePublishTask);
    document.getElementById('changePasswordForm').addEventListener('submit', handleChangePassword);
    document.getElementById('ratingForm').addEventListener('submit', handleAddRating);

    // 标签页切换
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const tab = this.getAttribute('data-tab');
            switchTab(tab);
        });
    });
}

// 更新已登录用户的UI
function updateUIForLoggedInUser() {
    document.getElementById('navAuth').style.display = 'none';
    document.getElementById('navUser').style.display = 'flex';
    document.getElementById('userInfo').textContent = `${currentUser.username} (信誉分: ${currentUser.reputation})`;
    
    // 加载用户数据
    loadUserData();
}

// 更新未登录用户的UI
function updateUIForLoggedOutUser() {
    document.getElementById('navAuth').style.display = 'flex';
    document.getElementById('navUser').style.display = 'none';
    currentUser = null;
}

// 显示页面
function showPage(pageName) {
    // 隐藏所有页面
    document.querySelectorAll('.page').forEach(page => {
        page.classList.remove('active');
    });

    // 显示指定页面
    const targetPage = document.getElementById(pageName + 'Page');
    if (targetPage) {
        targetPage.classList.add('active');
        
        // 根据页面类型加载数据
        switch(pageName) {
            case 'tasks':
                loadAvailableTasks();
                break;
            case 'my-tasks':
                loadMyTasks();
                break;
            case 'ratings':
                loadMyRatings();
                break;
            case 'profile':
                loadUserProfile();
                break;
        }
    }

    // 更新导航链接状态
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    document.querySelector(`[data-page="${pageName}"]`).classList.add('active');
}

// 显示模态框
function showModal(modalId) {
    document.getElementById(modalId).style.display = 'block';
}

// 关闭模态框
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
    // 清空表单
    const form = document.getElementById(modalId).querySelector('form');
    if (form) {
        form.reset();
    }
}

// 显示修改密码模态框
function showChangePasswordModal() {
    showModal('changePasswordModal');
}

// 显示评价模态框
function showRatingModal(taskId, revieweeId) {
    currentTaskId = taskId;
    currentRevieweeId = revieweeId;
    showModal('ratingModal');
}

// 设置默认截止时间
function setDefaultDeadline() {
    const deadlineInput = document.getElementById('deadline');
    if (deadlineInput) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        deadlineInput.value = tomorrow.toISOString().slice(0, 16);
    }
}

// 处理登录
async function handleLogin(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
        username: formData.get('username'),
        password: formData.get('password')
    };

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();
        
        if (response.ok) {
            localStorage.setItem('token', result.token);
            currentUser = result.user;
            updateUIForLoggedInUser();
            closeModal('loginModal');
            showMessage('登录成功', 'success');
            showPage('home');
        } else {
            showMessage(result.message || '登录失败', 'error');
        }
    } catch (error) {
        console.error('登录错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 处理注册
async function handleRegister(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
        username: formData.get('username'),
        email: formData.get('email'),
        phone: formData.get('phone'),
        password: formData.get('password')
    };

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/auth/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();
        
        if (response.ok) {
            localStorage.setItem('token', result.token);
            currentUser = result.user;
            updateUIForLoggedInUser();
            closeModal('registerModal');
            showMessage('注册成功', 'success');
            showPage('home');
        } else {
            showMessage(result.message || '注册失败', 'error');
        }
    } catch (error) {
        console.error('注册错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 处理发布任务
async function handlePublishTask(e) {
    e.preventDefault();
    
    if (!currentUser) {
        showMessage('请先登录', 'error');
        return;
    }

    const formData = new FormData(e.target);
    const data = {
        company: formData.get('company'),
        pickupPlace: formData.get('pickupPlace'),
        code: formData.get('code'),
        reward: parseFloat(formData.get('reward')),
        deadline: formData.get('deadline')
    };

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('任务发布成功', 'success');
            e.target.reset();
            setDefaultDeadline();
            showPage('my-tasks');
        } else if (response.status === 401 || response.status === 403) {
            // 认证失败，清除token并提示重新登录
            localStorage.removeItem('token');
            currentUser = null;
            updateUIForLoggedOutUser();
            showMessage('登录已过期，请重新登录后重试', 'error');
            closeModal('publishModal');
        } else {
            showMessage(result.message || '发布失败', 'error');
        }
    } catch (error) {
        console.error('发布任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 处理修改密码
async function handleChangePassword(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
        oldPassword: formData.get('oldPassword'),
        newPassword: formData.get('newPassword')
    };

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/auth/change-password`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('密码修改成功', 'success');
            closeModal('changePasswordModal');
        } else {
            showMessage(result.message || '修改失败', 'error');
        }
    } catch (error) {
        console.error('修改密码错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 处理添加评价
async function handleAddRating(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
        revieweeId: currentRevieweeId,
        taskId: currentTaskId,
        score: parseInt(formData.get('score')),
        comment: formData.get('comment')
    };

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/ratings`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('评价添加成功', 'success');
            closeModal('ratingModal');
            loadMyRatings();
        } else {
            showMessage(result.message || '评价失败', 'error');
        }
    } catch (error) {
        console.error('添加评价错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 加载待接任务列表
async function loadAvailableTasks() {
    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks/available`);
        const result = await response.json();
        
        if (response.ok) {
            displayTasks(result.tasks, 'tasksList', 'available');
        } else {
            showMessage(result.message || '加载失败', 'error');
        }
    } catch (error) {
        console.error('加载任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 加载我的任务
async function loadMyTasks() {
    if (!currentUser) {
        showMessage('请先登录', 'error');
        return;
    }

    try {
        showLoading();
        
        // 加载发布的任务
        const publishedResponse = await fetch(`${API_BASE}/tasks/published`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        const publishedResult = await publishedResponse.json();
        
        // 加载接取的任务
        const acceptedResponse = await fetch(`${API_BASE}/tasks/accepted`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        const acceptedResult = await acceptedResponse.json();
        
        if (publishedResponse.ok && acceptedResponse.ok) {
            displayTasks(publishedResult.tasks, 'publishedTasksList', 'published');
            displayTasks(acceptedResult.tasks, 'acceptedTasksList', 'accepted');
        } else {
            showMessage('加载任务失败', 'error');
        }
    } catch (error) {
        console.error('加载我的任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 显示任务列表
function displayTasks(tasks, containerId, type) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (tasks.length === 0) {
        container.innerHTML = '<p class="no-data">暂无数据</p>';
        return;
    }

    container.innerHTML = tasks.map(task => createTaskCard(task, type)).join('');
}

// 创建任务卡片
function createTaskCard(task, type) {
    const isPublisher = currentUser && task.publisherId === currentUser.uid;
    const isTaker = currentUser && task.takerId === currentUser.uid;
    
    let actions = '';
    const taskStatus = task.status || task.taskStatus;
    
    if (type === 'available' && currentUser && !isPublisher) {
        actions = `<button class="btn btn-primary" onclick="acceptTask(${task.tid})">接单</button>`;
    } else if (type === 'published') {
        if (task.status === 'pending') {
            actions = `<button class="btn btn-danger" onclick="deleteTask(${task.tid})">删除</button>`;
        } else if (task.status === 'accepted') {
            actions = `<button class="btn btn-warning" onclick="cancelTask(${task.tid}, 'publisher')">取消</button>`;
        }
    } else if (type === 'accepted') {
        if (task.assignmentStatus === 'in_progress') {
            actions = `
                <button class="btn btn-primary" onclick="completeTask(${task.tid})">完成任务</button>
                <button class="btn btn-secondary" onclick="cancelTask(${task.tid}, 'taker')">取消</button>
            `;
        } else if (task.assignmentStatus === 'completed') {
            // 评价按钮逻辑：只有在任务完成后，且自己不是评价发起方时才显示
            const otherUserId = isPublisher ? task.takerId : task.publisherId;
            actions = `<button class="btn btn-primary" onclick="showRatingModal(${task.tid}, ${otherUserId})">评价</button>`;
        }
    }

    return `
        <div class="task-card">
            <div class="task-header">
                <span class="task-company">${task.company}</span>
                <span class="task-reward">￥${task.reward}</span>
            </div>
            <div class="task-info">
                <p><strong>取件地点:</strong> ${task.pickupPlace}</p>
                <p><strong>取件码:</strong> ${task.code}</p>
                <p><strong>截止时间:</strong> ${formatDateTime(task.deadline)}</p>
                <p><strong>发布者:</strong> ${task.publisherName || '未知'}</p>
                ${task.takerName ? `<p><strong>接单者:</strong> ${task.takerName}</p>` : ''}
                <p><strong>状态:</strong> <span class="task-status ${getStatusClass(taskStatus)}">${getStatusText(taskStatus, task.assignmentStatus)}</span></p>
            </div>
            <div class="task-actions">
                ${actions}
            </div>
        </div>
    `;
}

// 获取状态样式类
function getStatusClass(status) {
    switch (status) {
        case 'pending':
            return 'status-pending';
        case 'accepted':
        case 'in_progress':
            return 'status-accepted';
        case 'completed':
            return 'status-completed';
        case 'cancelled':
            return 'status-cancelled';
        default:
            return 'status-pending';
    }
}

// 获取状态显示文本
function getStatusText(status, assignmentStatus = null) {
    if (status === 'accepted' && assignmentStatus === 'in_progress') {
        return '进行中';
    }
    switch (status) {
        case 'pending':
            return '待接单';
        case 'accepted':
            return '已接单';
        case 'completed':
            return '已完成';
        case 'cancelled':
            return '已取消';
        default:
            return '未知状态';
    }
}

// 接单
async function acceptTask(taskId) {
    if (!currentUser) {
        showMessage('请先登录', 'error');
        return;
    }

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks/${taskId}/accept`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('接单成功', 'success');
            loadAvailableTasks();
            showPage('my-tasks');
        } else {
            showMessage(result.message || '接单失败', 'error');
        }
    } catch (error) {
        console.error('接单错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 完成任务
async function completeTask(taskId) {
    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks/${taskId}/complete`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('任务完成', 'success');
            loadMyTasks();
        } else {
            showMessage(result.message || '操作失败', 'error');
        }
    } catch (error) {
        console.error('完成任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 取消任务
async function cancelTask(taskId, userType) {
    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks/${taskId}/cancel`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({ userType })
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('任务取消成功', 'success');
            loadMyTasks();
        } else {
            showMessage(result.message || '取消失败', 'error');
        }
    } catch (error) {
        console.error('取消任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 删除任务
async function deleteTask(taskId) {
    if (!confirm('确定要删除这个任务吗？')) {
        return;
    }

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/tasks/${taskId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });

        const result = await response.json();
        
        if (response.ok) {
            showMessage('任务删除成功', 'success');
            loadMyTasks();
        } else {
            showMessage(result.message || '删除失败', 'error');
        }
    } catch (error) {
        console.error('删除任务错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 刷新任务列表
function refreshTasks() {
    loadAvailableTasks();
}

// 切换标签页
function switchTab(tabName) {
    // 更新标签按钮状态
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // 更新内容区域
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tabName + 'Tasks').classList.add('active');
}

// 加载我的评价
async function loadMyRatings() {
    if (!currentUser) {
        showMessage('请先登录', 'error');
        return;
    }

    try {
        showLoading();
        const response = await fetch(`${API_BASE}/ratings/my-ratings`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });

        const result = await response.json();
        
        if (response.ok) {
            displayRatings(result.receivedRatings, 'receivedRatings');
            displayRatings(result.givenRatings, 'givenRatings');
        } else {
            showMessage(result.message || '加载失败', 'error');
        }
    } catch (error) {
        console.error('加载评价错误:', error);
        showMessage('网络错误，请稍后重试', 'error');
    } finally {
        hideLoading();
    }
}

// 显示评价列表
function displayRatings(ratings, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (ratings.length === 0) {
        container.innerHTML = '<p class="no-data">暂无评价</p>';
        return;
    }

    container.innerHTML = ratings.map(rating => `
        <div class="rating-item">
            <div class="rating-header">
                <span>${rating.reviewerName || rating.revieweeName}</span>
                <span class="rating-score">${rating.score}分</span>
            </div>
            <p><strong>任务:</strong> ${rating.company} - ${rating.pickupPlace}</p>
            ${rating.comment ? `<p class="rating-comment">${rating.comment}</p>` : ''}
            <p><small>${formatDateTime(rating.createTime)}</small></p>
        </div>
    `).join('');
}

// 加载用户资料
async function loadUserProfile() {
    if (!currentUser) {
        showMessage('请先登录', 'error');
        return;
    }

    const profileContainer = document.getElementById('userProfile');
    if (profileContainer) {
        profileContainer.innerHTML = `
            <p><strong>用户名:</strong> ${currentUser.username}</p>
            <p><strong>邮箱:</strong> ${currentUser.email}</p>
            <p><strong>手机号:</strong> ${currentUser.phone}</p>
            <p><strong>信誉分:</strong> ${currentUser.reputation}</p>
            <p><strong>注册时间:</strong> ${formatDateTime(currentUser.registerTime)}</p>
        `;
    }
}

// 加载用户数据
function loadUserData() {
    // 这里可以加载用户相关的其他数据
    // 比如用户统计信息等
}

// 退出登录
function logout() {
    localStorage.removeItem('token');
    currentUser = null;
    updateUIForLoggedOutUser();
    showPage('home');
    showMessage('已退出登录', 'success');
}

// 显示加载提示
function showLoading() {
    document.getElementById('loading').style.display = 'flex';
}

// 隐藏加载提示
function hideLoading() {
    document.getElementById('loading').style.display = 'none';
}

// 显示消息提示
function showMessage(text, type = 'info') {
    const messageEl = document.getElementById('message');
    const messageTextEl = document.getElementById('messageText');
    
    messageTextEl.textContent = text;
    messageEl.className = `message ${type}`;
    messageEl.style.display = 'flex';
    
    // 3秒后自动隐藏
    setTimeout(() => {
        hideMessage();
    }, 3000);
}

// 隐藏消息提示
function hideMessage() {
    document.getElementById('message').style.display = 'none';
}

// 格式化日期时间
function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// 点击模态框外部关闭
window.addEventListener('click', function(event) {
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
});

// 清除缓存并重新登录
function clearCacheAndReload() {
    // 清除localStorage
    localStorage.clear();
    // 清除sessionStorage
    sessionStorage.clear();
    // 重新加载页面
    window.location.reload(true);
} 