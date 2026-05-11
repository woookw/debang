// Supabase 配置
// 优先从 config.js 加载配置，如果不存在则使用环境变量或提示
let supabaseUrl, supabaseKey;

if (typeof SUPABASE_CONFIG !== 'undefined') {
  // 从本地配置文件加载
  supabaseUrl = SUPABASE_CONFIG.url;
  supabaseKey = SUPABASE_CONFIG.key;
} else {
  // 生产环境：从环境变量或提示
  console.warn('⚠️ 未找到 config.js，请确保已配置 Supabase 密钥');
  supabaseUrl = 'https://optvzautqwuyckorzmhs.supabase.co';
  supabaseKey = null; // 需要手动配置
}

// 初始化 Supabase 客户端
let supabase;
if (supabaseKey) {
  supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
} else {
  console.error('❌ Supabase 密钥未配置，请在 config.js 中设置');
}

// 测试 Supabase 连接
async function testSupabaseConnection() {
  if (!supabase) {
    console.error('Supabase 客户端未初始化');
    return;
  }
  try {
    const { data, error } = await supabase.auth.getSession();
    if (error) {
      console.warn('Supabase 连接警告:', error.message);
    } else {
      console.log('✅ Supabase 客户端初始化成功');
    }
  } catch (err) {
    console.error('Supabase 初始化失败:', err);
  }
}

// 页面加载时测试连接
document.addEventListener('DOMContentLoaded', testSupabaseConnection);

// 获取页面元素
const loginPage = document.getElementById('login-page');
const productionPage = document.getElementById('production-page');
const maintenancePage = document.getElementById('maintenance-page');
const managerPage = document.getElementById('manager-page');
const btnProduction = document.getElementById('btn-production');
const btnMaintenance = document.getElementById('btn-maintenance');
const btnManager = document.getElementById('btn-manager');
const logoutProduction = document.getElementById('logout-production');
const logoutMaintenance = document.getElementById('logout-maintenance');
const logoutManager = document.getElementById('logout-manager');
const backToMainProduction = document.getElementById('back-to-main-production');
const backToMainMaintenance = document.getElementById('back-to-main-maintenance');
const backToMainManager = document.getElementById('back-to-main-manager');
const productionFeedbackForm = document.getElementById('production-feedback-form');
const maintenanceRecordForm = document.getElementById('maintenance-record-form');

// 角色登录逻辑
function showPage(page) {
  // 隐藏所有页面
  [loginPage, productionPage, maintenancePage, managerPage].forEach(p => {
    p.classList.add('hidden');
  });
  
  // 显示选中页面
  page.classList.remove('hidden');
  page.classList.add('fade-in');
}

// 绑定登录按钮事件
btnProduction.addEventListener('click', () => {
  showPage(productionPage);
});

btnMaintenance.addEventListener('click', () => {
  showPage(maintenancePage);
});

btnManager.addEventListener('click', () => {
  showPage(managerPage);
  // 初始化管理人员页面的图表
  initManagerCharts();
});

// 绑定退出按钮事件
logoutProduction.addEventListener('click', () => {
  showPage(loginPage);
});

logoutMaintenance.addEventListener('click', () => {
  showPage(loginPage);
});

logoutManager.addEventListener('click', () => {
  showPage(loginPage);
});

// 绑定返回主界面按钮事件
backToMainProduction.addEventListener('click', () => {
  showPage(loginPage);
});

backToMainMaintenance.addEventListener('click', () => {
  showPage(loginPage);
});

backToMainManager.addEventListener('click', () => {
  showPage(loginPage);
});

// 表单提交处理
productionFeedbackForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  // 获取表单数据
  const feedbackType = document.getElementById('feedback-type').value;
  const feedbackLocation = document.getElementById('feedback-location').value;
  const feedbackDescription = document.getElementById('feedback-description').value;
  
  // 简单验证
  if (!feedbackLocation || !feedbackDescription) {
    alert('请填写完整的问题信息');
    return;
  }
  
  // 提交到 Supabase
  if (supabase) {
    try {
      const { data, error } = await supabase
        .from('feedbacks')
        .insert([
          {
            type: feedbackType,
            location: feedbackLocation,
            description: feedbackDescription,
            status: 'pending'
          }
        ]);
      
      if (error) {
        console.error('提交失败:', error);
        alert('提交失败: ' + error.message);
      } else {
        alert('反馈已提交成功！');
        productionFeedbackForm.reset();
      }
    } catch (err) {
      console.error('提交出错:', err);
      alert('提交出错，请检查网络连接');
    }
  } else {
    // 模拟提交
    alert('反馈已提交成功！(模拟)');
    productionFeedbackForm.reset();
  }
});

maintenanceRecordForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  // 获取表单数据
  const recordType = document.getElementById('record-type').value;
  const equipmentName = document.getElementById('equipment-name').value;
  const equipmentLocation = document.getElementById('equipment-location').value;
  const maintenanceTime = document.getElementById('maintenance-time').value;
  const failureReason = document.getElementById('failure-reason').value;
  const maintenanceContent = document.getElementById('maintenance-content').value;
  const maintenanceResult = document.getElementById('maintenance-result').value;
  
  // 简单验证
  if (!equipmentName || !equipmentLocation || !maintenanceTime || !maintenanceContent) {
    alert('请填写完整的维护记录信息');
    return;
  }
  
  // 提交到 Supabase
  if (supabase) {
    try {
      const { data, error } = await supabase
        .from('maintenance_records')
        .insert([
          {
            type: recordType,
            equipment_name: equipmentName,
            equipment_location: equipmentLocation,
            maintenance_time: maintenanceTime,
            failure_reason: failureReason,
            maintenance_content: maintenanceContent,
            result: maintenanceResult
          }
        ]);
      
      if (error) {
        console.error('保存失败:', error);
        alert('保存失败: ' + error.message);
      } else {
        alert('维护记录已保存成功！');
        maintenanceRecordForm.reset();
      }
    } catch (err) {
      console.error('保存出错:', err);
      alert('保存出错，请检查网络连接');
    }
  } else {
    // 模拟提交
    alert('维护记录已保存成功！(模拟)');
    maintenanceRecordForm.reset();
  }
});

// 初始化管理人员页面的图表
function initManagerCharts() {
  try {
    // 检查 Chart 对象是否存在
    if (typeof Chart === 'undefined') {
      console.error('Chart.js 未正确加载');
      return;
    }
    
    // 模拟数据
    const problemTypeDistribution = {
      '机械故障': 15,
      '电气故障': 8,
      '软件问题': 5,
      '其他问题': 2
    };
    
    const maintenanceTrend = {
      labels: ['1月', '2月', '3月', '4月', '5月', '6月'],
      repairData: [5, 8, 12, 9, 15, 10],
      maintenanceData: [10, 12, 8, 15, 18, 14]
    };
    
    // 问题类型分布图表
    const problemTypeCtx = document.getElementById('problem-type-chart');
    if (problemTypeCtx) {
      // 销毁已存在的图表实例（如果有）
      if (window.problemTypeChart) {
        window.problemTypeChart.destroy();
      }
      
      window.problemTypeChart = new Chart(problemTypeCtx, {
        type: 'pie',
        data: {
          labels: Object.keys(problemTypeDistribution),
          datasets: [{
            data: Object.values(problemTypeDistribution),
            backgroundColor: [
              '#165DFF',
              '#36CFC9',
              '#FAAD14',
              '#94A3B8'
            ],
            borderWidth: 0,
            hoverOffset: 4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'right',
              labels: {
                padding: 20,
                font: {
                  size: 12
                }
              }
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  const label = context.label || '';
                  const value = context.raw || 0;
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const percentage = Math.round((value / total) * 100);
                  return `${label}: ${value} (${percentage}%)`;
                }
              }
            }
          }
        }
      });
    }
    
    // 月度维保趋势图表
    const maintenanceTrendCtx = document.getElementById('maintenance-trend-chart');
    if (maintenanceTrendCtx) {
      // 销毁已存在的图表实例（如果有）
      if (window.maintenanceTrendChart) {
        window.maintenanceTrendChart.destroy();
      }
      
      window.maintenanceTrendChart = new Chart(maintenanceTrendCtx, {
        type: 'line',
        data: {
          labels: maintenanceTrend.labels,
          datasets: [
            {
              label: '故障维修',
              data: maintenanceTrend.repairData,
              borderColor: '#165DFF',
              backgroundColor: 'rgba(22, 93, 255, 0.1)',
              tension: 0.3,
              fill: true
            },
            {
              label: '定期保养',
              data: maintenanceTrend.maintenanceData,
              borderColor: '#36CFC9',
              backgroundColor: 'rgba(54, 207, 201, 0.1)',
              tension: 0.3,
              fill: true
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              beginAtZero: true,
              grid: {
                drawBorder: false
              }
            },
            x: {
              grid: {
                display: false
              }
            }
          },
          plugins: {
            legend: {
              position: 'top',
              labels: {
                boxWidth: 12,
                padding: 15
              }
            },
            tooltip: {
              mode: 'index',
              intersect: false
            }
          },
          interaction: {
            mode: 'nearest',
            axis: 'x',
            intersect: false
          }
        }
      });
    }
  } catch (error) {
    console.error('图表初始化错误:', error);
  }
}

// 响应式处理
function handleResponsive() {
  const viewportWidth = window.innerWidth;
  // 可以根据不同的视口宽度调整页面元素样式
}

// 页面加载完成后初始化
window.addEventListener('DOMContentLoaded', () => {
  try {
    handleResponsive();
    
    // 图片上传处理
    const uploadAreas = document.querySelectorAll('.border-dashed');
    uploadAreas.forEach(area => {
      const fileInput = area.querySelector('input[type="file"]');
      
      if (fileInput) {
        area.addEventListener('click', () => {
          fileInput.click();
        });
        
        area.addEventListener('dragover', (e) => {
          e.preventDefault();
          area.classList.add('border-primary');
        });
        
        area.addEventListener('dragleave', () => {
          area.classList.remove('border-primary');
        });
        
        area.addEventListener('drop', (e) => {
          e.preventDefault();
          area.classList.remove('border-primary');
          // 这里可以处理拖放的文件
        });
      }
    });
  } catch (error) {
    console.error('页面初始化错误:', error);
  }
});

// 监听窗口大小变化
window.addEventListener('resize', handleResponsive);

// 导出一些函数以便在浏览器控制台调试（如果需要）
window.app = {
  showPage,
  initManagerCharts
};
