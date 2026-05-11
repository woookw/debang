# 得邦智能化工厂管理系统

## 项目概述
这是一个面向得邦智能化工厂的网页端管理系统，提供生产人员、维保人员和管理人员三种角色的工作台功能，实现生产问题反馈、设备维修保养记录和管理数据分析的数字化管理。

## 功能模块

### 1. 生产人员端
- 生产/设备问题反馈表单
- 设备状态查看入口
- 反馈历史记录查询
- 生产效率指标查看

### 2. 维保人员端
- 待处理任务列表展示
- 任务统计数据卡片
- 维修保养记录表单
- 月度维保计划完成情况

### 3. 管理人员端
- 关键指标实时监控
- 问题类型分布图表
- 月度维保趋势分析
- 全工厂问题反馈列表管理
- 问题分配与处理状态跟踪

## 技术栈
- HTML5 + CSS3
- JavaScript (原生)
- Tailwind CSS v3 (样式框架)
- Font Awesome (图标库)
- Chart.js (数据可视化)
- Supabase (后端服务)

## 快速开始

### 1. 配置 Supabase

#### 创建 Supabase 项目
1. 访问 [Supabase](https://supabase.com/) 并创建新项目
2. 进入 **SQL Editor**
3. 复制 `supabase-database.sql` 的内容并执行

#### 获取 API 密钥
1. 进入 **Settings** → **API**
2. 复制 `anon public` 密钥

#### 配置本地密钥
1. 复制 `config.example.js` 为 `config.js`
2. 在 `config.js` 中填入您的 Supabase 密钥：
```javascript
const SUPABASE_CONFIG = {
  url: 'https://your-project.supabase.co',
  key: 'your-anon-key-here'
};
```
3. **重要**：`config.js` 已添加到 `.gitignore`，不会被上传到 GitHub

### 2. 运行项目

#### 开发模式
```bash
# 使用 Python 启动简单服务器
python -m http.server 8000

# 或使用 npm
npx serve .
```

#### 生产部署
项目可部署到以下平台：
- GitHub Pages
- Vercel
- Netlify
- 任何静态文件托管服务

## 项目结构
```
├── index.html          # 主页面文件，包含所有UI结构
├── app.js              # JavaScript 逻辑文件
├── config.js           # 本地配置文件（包含密钥，不上传GitHub）⚠️
├── config.example.js   # 配置示例文件（可上传GitHub）
├── supabase-database.sql  # Supabase 数据库脚本（含 RLS）
├── database.sql        # 通用 PostgreSQL 数据库脚本
├── DATABASE_README.md  # 数据库配置说明
├── README.md           # 项目说明文档
└── .gitignore          # Git 忽略文件配置
```

## 数据库设计

### 表结构
| 表名 | 说明 |
|------|------|
| `users` | 用户信息表 |
| `equipment` | 设备信息表 |
| `feedbacks` | 问题反馈表 |
| `maintenance_records` | 维护记录表 |
| `comments` | 评论跟进表 |

### 角色权限
- **production** (生产人员): 可查看设备、提交反馈、查看自己的反馈记录
- **maintenance** (维保人员): 可查看设备、处理反馈、创建维护记录
- **manager** (管理人员): 完整权限，可查看和管理所有数据

## 安全说明

### RLS 策略
项目已配置完整的 Row Level Security：
- 用户只能查看自己的反馈记录
- 维保人员和管理人员可修改设备信息
- 反馈提交者、被分配者和管理人员可更新反馈状态

### 重要提醒
1. 切勿将 API 密钥提交到版本控制系统
2. 在生产环境中启用 HTTPS
3. 定期审查数据库访问日志

## 浏览器兼容性
- Chrome：最新版本
- Firefox：最新版本
- Safari：最新版本
- Edge：最新版本

## 贡献指南
欢迎提交 Issue 和 Pull Request！

## 许可证
MIT License