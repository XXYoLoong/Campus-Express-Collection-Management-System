const { getPool } = require('./backend/config/database');

async function testDatabaseStructure() {
    try {
        console.log('=== 数据库结构测试 ===');
        
        const pool = getPool();
        
        // 1. 测试表是否存在
        console.log('\n1. 检查表结构...');
        const [tables] = await pool.execute('SHOW TABLES');
        console.log('✅ 数据库表:', tables.map(t => Object.values(t)[0]));
        
        // 2. 测试视图是否存在
        console.log('\n2. 检查视图...');
        const [views] = await pool.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
        console.log('✅ 数据库视图:', views.map(v => Object.values(v)[0]));
        
        // 3. 测试存储过程是否存在
        console.log('\n3. 检查存储过程...');
        const [procedures] = await pool.execute('SHOW PROCEDURE STATUS WHERE Db = "express_delivery_system"');
        console.log('✅ 存储过程:', procedures.map(p => p.Name));
        
        // 4. 测试数据查询
        console.log('\n4. 测试数据查询...');
        
        // 用户数据
        const [users] = await pool.execute('SELECT COUNT(*) as count FROM User');
        console.log(`✅ 用户数量: ${users[0].count}`);
        
        // 任务数据
        const [tasks] = await pool.execute('SELECT COUNT(*) as count FROM DeliveryTask');
        console.log(`✅ 任务数量: ${tasks[0].count}`);
        
        // 任务状态分布
        const [taskStatus] = await pool.execute('SELECT status, COUNT(*) as count FROM DeliveryTask GROUP BY status');
        console.log('✅ 任务状态分布:', taskStatus);
        
        // 5. 测试视图查询
        console.log('\n5. 测试视图查询...');
        
        // 可用任务视图
        const [availableTasks] = await pool.execute('SELECT COUNT(*) as count FROM View_AvailableTasks');
        console.log(`✅ 可用任务数量: ${availableTasks[0].count}`);
        
        // 用户评价统计视图
        const [userStats] = await pool.execute('SELECT COUNT(*) as count FROM View_UserRatingStats');
        console.log(`✅ 用户统计数量: ${userStats[0].count}`);
        
        // 6. 测试存储过程
        console.log('\n6. 测试存储过程...');
        
        // 测试接单存储过程（不实际执行，只检查是否存在）
        const [acceptTaskProc] = await pool.execute('SHOW CREATE PROCEDURE AcceptTask');
        console.log('✅ AcceptTask存储过程存在');
        
        const [completeTaskProc] = await pool.execute('SHOW CREATE PROCEDURE CompleteTask');
        console.log('✅ CompleteTask存储过程存在');
        
        const [cancelTaskProc] = await pool.execute('SHOW CREATE PROCEDURE CancelTask');
        console.log('✅ CancelTask存储过程存在');
        
        const [addRatingProc] = await pool.execute('SHOW CREATE PROCEDURE AddRating');
        console.log('✅ AddRating存储过程存在');
        
        console.log('\n=== 数据库结构测试完成 ===');
        console.log('✅ 所有表、视图、存储过程都正常');
        
    } catch (error) {
        console.error('❌ 数据库结构测试失败:', error);
    }
}

testDatabaseStructure(); 