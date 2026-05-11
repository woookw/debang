# 得邦智能化工厂管理系统 - 数据库配置

## 数据库表结构

### 1. users（用户表）
- 存储系统用户信息
- 包含三种角色：production（生产人员）、maintenance（维保人员）、manager（管理人员）
- 与 Supabase Auth 集成

### 2. equipment（设备表）
- 存储工厂设备信息
- 设备状态：normal（正常）、warning（警告）、fault（故障）、maintenance（维护中）

### 3. feedbacks（问题反馈表）
- 存储生产/设备问题反馈
- 问题类型：production、equipment、material、other
- 处理状态：pending、processing、resolved、closed

### 4. maintenance_records（维护记录表）
- 存储设备维护记录
- 记录类型：repair（故障维修）、maintenance（定期保养）、inspection（设备检查）、upgrade（设备升级）

### 5. comments（评论/跟进记录表）
- 存储对问题反馈的评论和跟进信息

## 快速开始

### 方式一：使用 Supabase（推荐）

1. 在 Supabase 中创建新项目
2. 进入 SQL Editor
3. 复制 `supabase-database.sql` 的内容并执行
4. 配置项目的 URL 和 Key

### 方式二：使用通用 PostgreSQL

1. 创建 PostgreSQL 数据库
2. 执行 `database.sql` 文件

## JavaScript 使用示例

### 查询所有问题反馈
```javascript
const { data: feedbacks, error } = await supabase
  .from('feedbacks')
  .select('*, reporter:users!reporter_id(*), assignee:users!assignee_id(*)')
  .order('created_at', { ascending: false });
```

### 创建新的问题反馈
```javascript
const { data, error } = await supabase
  .from('feedbacks')
  .insert({
    type: 'equipment',
    location: '装配车间-生产线2',
    description: '机械臂出现异常',
    reporter_id: userId
  })
  .select();
```

### 上传图片
```javascript
const { data, error } = await supabase.storage
  .from('feedback-images')
  .upload(`public/${file.name}`, file);
```

### 获取用户角色
```javascript
const { data: user } = await supabase
  .from('users')
  .select('role')
  .eq('id', userId)
  .single();
```

## 数据库关系图

```
auth.users (Supabase Auth)
    ↓ 1:1
users
    ↓ 1:N ──────────────┬──────────────┐
    ↓                   ↓              ↓
feedbacks ←────── comments    maintenance_records
    ↑
equipment
```
