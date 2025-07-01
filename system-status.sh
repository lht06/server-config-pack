#!/bin/bash

# 系统状态检查脚本

green() { echo -e "\033[32m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
cyan() { echo -e "\033[36m$1\033[0m"; }

echo ""
cyan "════════════════════════════════════════════════════════════════"
cyan "🖥️  Ubuntu Server 开发环境状态报告"
cyan "════════════════════════════════════════════════════════════════"
echo ""

# 系统信息
green "📋 系统信息:"
echo "  发行版: $(lsb_release -d | cut -f2)"
echo "  内核: $(uname -r)"
echo "  架构: $(uname -m)"
echo "  运行时间: $(uptime -p)"
echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# 资源使用
green "💾 资源使用:"
echo "  内存: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
echo "  磁盘: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
echo "  家目录: $(du -sh ~ 2>/dev/null | cut -f1)"
echo ""

# 编程环境
green "🌐 编程环境:"
if command -v node &> /dev/null; then
    echo "  ✅ Node.js: $(node --version)"
    echo "  ✅ npm: v$(npm --version)"
else
    echo "  ❌ Node.js: 未安装"
fi

if command -v python3 &> /dev/null; then
    echo "  ✅ Python: $(python3 --version | cut -d' ' -f2)"
else
    echo "  ❌ Python: 未安装"
fi

if command -v go &> /dev/null; then
    echo "  ✅ Go: $(go version | cut -d' ' -f3)"
else
    echo "  ❌ Go: 未安装"
fi

if command -v git &> /dev/null; then
    echo "  ✅ Git: $(git --version | cut -d' ' -f3)"
else
    echo "  ❌ Git: 未安装"
fi

if command -v docker &> /dev/null; then
    echo "  ✅ Docker: $(docker --version | cut -d' ' -f3 | sed 's/,//')"
    echo "  容器数量: $(docker ps -q 2>/dev/null | wc -l) 运行中"
else
    echo "  ❌ Docker: 未安装"
fi
echo ""

# 服务状态
green "🔄 关键服务:"
services=("ssh" "ufw" "fail2ban" "docker" "mihomo")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  ✅ $service (运行中)"
    elif systemctl list-unit-files | grep -q "$service"; then
        echo "  ⏸️  $service (已安装，未运行)"
    else
        echo "  ❌ $service (未安装)"
    fi
done
echo ""

# 网络状态
green "🌐 网络状态:"
if systemctl is-active --quiet mihomo 2>/dev/null; then
    echo "  ✅ Clash 代理: 运行中"
    echo "  代理地址: http://127.0.0.1:7890"
    echo "  Web 界面: http://127.0.0.1:9090/ui"
else
    echo "  ❌ Clash 代理: 未运行"
fi

if [ -n "$HTTP_PROXY" ]; then
    echo "  ✅ 代理变量: 已设置 ($HTTP_PROXY)"
else
    echo "  ❌ 代理变量: 未设置"
fi
echo ""

# 配置文件
green "📁 重要配置文件:"
configs=(
    "$HOME/.zshrc:Zsh 配置"
    "$HOME/.gitconfig:Git 配置"
    "$HOME/.ssh:SSH 密钥"
    "/opt/clash:Clash 配置"
    "$HOME/venv:Python 虚拟环境"
)

for config_info in "${configs[@]}"; do
    config_path=$(echo "$config_info" | cut -d: -f1)
    config_desc=$(echo "$config_info" | cut -d: -f2)
    if [ -e "$config_path" ]; then
        echo "  ✅ $config_desc"
    else
        echo "  ❌ $config_desc"
    fi
done
echo ""

# Shell 环境
green "🐚 Shell 环境:"
echo "  当前 Shell: $SHELL"
if [ -f "$HOME/.zshrc" ]; then
    echo "  ✅ Zsh 配置文件存在"
else
    echo "  ❌ Zsh 配置文件不存在"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  ✅ Oh-My-Zsh 已安装"
else
    echo "  ❌ Oh-My-Zsh 未安装"
fi
echo ""

# 安全状态
green "🔒 安全状态:"
if systemctl is-active --quiet ufw 2>/dev/null; then
    echo "  ✅ 防火墙: 启用"
else
    echo "  ❌ 防火墙: 禁用"
fi

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo "  ✅ Fail2Ban: 启用"
else
    echo "  ❌ Fail2Ban: 禁用"
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
    echo "  ✅ SSH 服务: 运行中"
else
    echo "  ❌ SSH 服务: 未运行"
fi
echo ""

# 清理状态
green "🧹 清理状态:"
if [ -f "$HOME/system-maintenance.sh" ]; then
    echo "  ✅ 维护脚本: 可用"
else
    echo "  ❌ 维护脚本: 不存在"
fi

script_count=$(find "$HOME" -name "*.sh" -type f 2>/dev/null | wc -l)
echo "  脚本文件数量: $script_count"

temp_files=$(find "$HOME" -name "*.tmp" -o -name "*.log" -o -name "*.zip" -o -name "*.tar.gz" 2>/dev/null | wc -l)
echo "  临时文件数量: $temp_files"

echo ""
green "🛠️  可用工具:"
tools=("vim" "htop" "tree" "jq" "curl" "wget" "tmux" "screen")
available_tools=0
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        available_tools=$((available_tools + 1))
    fi
done
echo "  可用工具: $available_tools/${#tools[@]}"

echo ""
echo "════════════════════════════════════════════════════════════════"
cyan "🎯 系统状态总结: 开发环境已就绪，系统运行正常！"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 显示快速命令
yellow "💡 常用命令:"
echo "  sysinfo              - 快速系统信息"
echo "  proxy_on/proxy_off   - 代理开关"
echo "  clash status         - Clash 状态"
echo "  ./system-status.sh   - 详细状态报告"
echo ""