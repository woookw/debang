-- 得邦智能化工厂管理系统数据库结构
-- 创建时间: 2025-09-15

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('production', 'maintenance', 'manager')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 设备表
CREATE TABLE IF NOT EXISTS equipment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200) NOT NULL,
    status VARCHAR(20) DEFAULT 'normal' CHECK (status IN ('normal', 'warning', 'fault', 'maintenance')),
    last_maintenance_date TIMESTAMP WITH TIME ZONE,
    next_maintenance_date TIMESTAMP WITH TIME ZONE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 问题反馈表
CREATE TABLE IF NOT EXISTS feedbacks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('production', 'equipment', 'material', 'other')),
    location VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    images TEXT[], -- 存储图片URL数组
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'resolved', 'closed')),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    reporter_id UUID REFERENCES users(id),
    assignee_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 维护记录表
CREATE TABLE IF NOT EXISTS maintenance_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('repair', 'maintenance', 'inspection', 'upgrade')),
    equipment_id UUID REFERENCES equipment(id),
    equipment_name VARCHAR(100),
    equipment_location VARCHAR(200),
    maintenance_time TIMESTAMP WITH TIME ZONE NOT NULL,
    failure_reason TEXT,
    maintenance_content TEXT NOT NULL,
    result VARCHAR(20) NOT NULL CHECK (result IN ('success', 'partial', 'pending', 'failed')),
    operator_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 评论/跟进记录表
CREATE TABLE IF NOT EXISTS comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    feedback_id UUID REFERENCES feedbacks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_feedbacks_status ON feedbacks(status);
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON feedbacks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_reporter ON feedbacks(reporter_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_assignee ON feedbacks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_equipment ON maintenance_records(equipment_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_time ON maintenance_records(maintenance_time DESC);
CREATE INDEX IF NOT EXISTS idx_equipment_status ON equipment(status);
CREATE INDEX IF NOT EXISTS idx_comments_feedback ON comments(feedback_id);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为各个表添加更新时间触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON equipment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feedbacks_updated_at BEFORE UPDATE ON feedbacks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_records_updated_at BEFORE UPDATE ON maintenance_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO users (username, email, role) VALUES
('张三', 'zhangsan@example.com', 'production'),
('李四', 'lisi@example.com', 'maintenance'),
('王五', 'wangwu@example.com', 'manager'),
('赵六', 'zhaoliu@example.com', 'production');

INSERT INTO equipment (name, location, status, description) VALUES
('机械臂A', '装配车间-生产线2-工位3', 'normal', '主要装配机械臂'),
('注塑机3', '注塑车间-设备3', 'warning', '需要月度维护'),
('包装线1', '包装车间-生产线1', 'normal', '产品包装生产线'),
('冲压机1', '冲压车间-生产线1-工位4', 'fault', '需要维修');

INSERT INTO feedbacks (type, location, description, status, priority, reporter_id) VALUES
('equipment', '装配车间-生产线2-工位3', '装配线2的机械臂出现异常，需要立即检查和维修。', 'processing', 'urgent', (SELECT id FROM users WHERE username = '张三')),
('production', '包装车间-生产线1-工位2', '包装材料供应不足，需要补充。', 'resolved', 'normal', (SELECT id FROM users WHERE username = '赵六')),
('material', '注塑车间-生产线3-工位5', '原材料质量有问题，影响产品质量。', 'resolved', 'high', (SELECT id FROM users WHERE username = '张三')),
('equipment', '冲压车间-生产线1-工位4', '冲压机1出现异响，需要检查。', 'pending', 'high', (SELECT id FROM users WHERE username = '赵六'));

INSERT INTO maintenance_records (type, equipment_name, equipment_location, maintenance_time, failure_reason, maintenance_content, result, operator_id) VALUES
('repair', '机械臂A', '装配车间-生产线2-工位3', NOW() - INTERVAL '2 hours', '传感器故障', '更换了位置传感器', 'success', (SELECT id FROM users WHERE username = '李四')),
('maintenance', '注塑机3', '注塑车间-设备3', NOW() - INTERVAL '1 day', NULL, '检查液压系统和温控系统，更换润滑油', 'success', (SELECT id FROM users WHERE username = '李四')),
('inspection', '包装线1', '包装车间-生产线1', NOW() - INTERVAL '3 days', NULL, '全面检查电气控制系统', 'success', (SELECT id FROM users WHERE username = '李四'));
