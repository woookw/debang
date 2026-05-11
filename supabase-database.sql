-- Supabase 数据库结构配置
-- 得邦智能化工厂管理系统

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 用户表 (与 Supabase Auth 集成)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100),
    role VARCHAR(20) NOT NULL CHECK (role IN ('production', 'maintenance', 'manager')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 设备表
CREATE TABLE IF NOT EXISTS equipment (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
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
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('production', 'equipment', 'material', 'other')),
    location VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    images TEXT[],
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'resolved', 'closed')),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    reporter_id UUID REFERENCES users(id),
    assignee_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 维护记录表
CREATE TABLE IF NOT EXISTS maintenance_records (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
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
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    feedback_id UUID REFERENCES feedbacks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
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

-- 启用 RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有认证用户可以查看用户信息
CREATE POLICY "Users are viewable by authenticated users" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

-- RLS 策略：用户只能更新自己的信息
CREATE POLICY "Users can update own record" ON users
    FOR UPDATE USING (auth.uid() = id);

-- RLS 策略：所有认证用户可以查看设备信息
CREATE POLICY "Equipment is viewable by authenticated users" ON equipment
    FOR SELECT USING (auth.role() = 'authenticated');

-- RLS 策略：维护人员和管理人员可以修改设备信息
CREATE POLICY "Equipment is modifiable by maintenance and managers" ON equipment
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('maintenance', 'manager')
        )
    );

-- RLS 策略：所有认证用户可以查看反馈
CREATE POLICY "Feedbacks are viewable by authenticated users" ON feedbacks
    FOR SELECT USING (auth.role() = 'authenticated');

-- RLS 策略：所有认证用户可以创建反馈
CREATE POLICY "Feedbacks can be created by authenticated users" ON feedbacks
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS 策略：反馈提交者、被分配者和管理人员可以更新反馈
CREATE POLICY "Feedbacks can be updated by reporter, assignee, or managers" ON feedbacks
    FOR UPDATE USING (
        reporter_id = auth.uid() OR 
        assignee_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'manager'
        )
    );

-- RLS 策略：所有认证用户可以查看维护记录
CREATE POLICY "Maintenance records are viewable by authenticated users" ON maintenance_records
    FOR SELECT USING (auth.role() = 'authenticated');

-- RLS 策略：维护人员和管理人员可以创建/更新维护记录
CREATE POLICY "Maintenance records can be modified by maintenance and managers" ON maintenance_records
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('maintenance', 'manager')
        )
    );

-- RLS 策略：所有认证用户可以查看评论
CREATE POLICY "Comments are viewable by authenticated users" ON comments
    FOR SELECT USING (auth.role() = 'authenticated');

-- RLS 策略：所有认证用户可以创建评论
CREATE POLICY "Comments can be created by authenticated users" ON comments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 创建函数：自动创建用户记录（当新用户通过 Auth 注册时）
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, username, email, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'username', new.email),
        new.email,
        COALESCE(new.raw_user_meta_data->>'role', 'production')
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器：在 Auth 用户创建时自动触发
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 创建存储桶用于文件上传
INSERT INTO storage.buckets (id, name, public)
VALUES ('feedback-images', 'feedback-images', true)
ON CONFLICT (id) DO NOTHING;

-- 设置存储桶 RLS 策略
CREATE POLICY "Authenticated users can upload feedback images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'feedback-images' AND
        auth.role() = 'authenticated'
    );

CREATE POLICY "Public can view feedback images" ON storage.objects
    FOR SELECT USING (bucket_id = 'feedback-images');
