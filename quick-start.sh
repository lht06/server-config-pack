#!/bin/bash

# 服务器配置包快速启动脚本

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
cyan() { echo -e "\033[36m$1\033[0m"; }

# 显示横幅
show_banner() {
    clear
    cyan "══════════════════════════════════════════════════════════════════"
    cyan "🚀 Ubuntu Server 开发环境配置包"
    cyan "══════════════════════════════════════════════════════════════════"
    echo ""
    green "版本: v1.0"
    green "支持: Ubuntu 24.04 LTS"
    green "包含: 开发工具 + Clash 代理 + 安全配置 + 文档"
    echo ""
}

# 显示菜单
show_menu() {
    echo "请选择要执行的操作:"
    echo ""
    echo "  1) 🛠️  完整安装开发环境 (推荐)"
    echo "  2) 🌐 仅安装 Clash 代理"
    echo "  3) 📋 查看系统状态"
    echo "  4) 📚 查看安装文档"
    echo "  5) 🔧 查看故障排除指南"
    echo "  6) 📱 查看 iTerm2 配置指南"
    echo "  7) ⚙️  运行特定脚本"
    echo "  8) 🚪 退出"
    echo ""
}

# 运行系统检查
run_system_check() {
    echo "🔍 系统环境检查..."
    echo "════════════════════════════════════"
    echo ""
    
    # 系统信息
    echo "📋 系统信息:"
    echo "  发行版: $(lsb_release -d | cut -f2)"
    echo "  内核: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  用户: $(whoami)"
    echo ""
    
    # 检查权限
    echo "🔑 权限检查:"
    if sudo -n true 2>/dev/null; then
        echo "  ✅ sudo 权限可用"
    else
        echo "  ⚠️  sudo 权限需要密码"
    fi
    echo ""
    
    # 检查网络
    echo "🌐 网络检查:"
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "  ✅ 网络连接正常"
    else
        echo "  ❌ 网络连接失败"
    fi
    echo ""
    
    # 检查磁盘空间
    echo "💿 磁盘空间:"
    df -h / | tail -1 | awk '{print "  可用空间: " $4 " / " $2 " (使用: " $5 ")"}'
    echo ""
    
    # 检查已安装的工具
    echo "🛠️  已安装工具:"
    tools=("git" "curl" "wget" "vim" "zsh" "docker" "node" "python3" "go")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool"
        fi
    done
    echo ""
    
    # 检查服务状态
    echo "🔄 服务状态:"
    services=("ssh" "ufw" "docker" "mihomo")
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
    echo "════════════════════════════════════"
}

# 显示特定脚本菜单
show_script_menu() {
    echo ""
    echo "可用的脚本:"
    echo ""
    echo "  1) system-monitor.sh     - 系统监控面板"
    echo "  2) proxy-manager.sh      - 代理管理工具"
    echo "  3) dev-env-manager.sh    - 开发环境管理"
    echo "  4) clash-manager.sh      - Clash 服务管理"
    echo "  5) 返回主菜单"
    echo ""
}

# 运行特定脚本
run_specific_script() {
    while true; do
        show_script_menu
        read -p "请选择脚本 [1-5]: " script_choice
        
        case $script_choice in
            1)
                if [ -f "./scripts/system-monitor.sh" ]; then
                    ./scripts/system-monitor.sh
                else
                    echo "❌ 脚本不存在: system-monitor.sh"
                fi
                ;;
            2)
                if [ -f "./scripts/proxy-manager.sh" ]; then
                    ./scripts/proxy-manager.sh status
                else
                    echo "❌ 脚本不存在: proxy-manager.sh"
                fi
                ;;
            3)
                if [ -f "./scripts/dev-env-manager.sh" ]; then
                    ./scripts/dev-env-manager.sh status
                else
                    echo "❌ 脚本不存在: dev-env-manager.sh"
                fi
                ;;
            4)
                if [ -f "./scripts/clash-manager.sh" ]; then
                    ./scripts/clash-manager.sh status
                else
                    echo "❌ 脚本不存在: clash-manager.sh"
                fi
                ;;
            5)
                return
                ;;
            *)
                echo "❌ 无效选择"
                ;;
        esac
        
        echo ""
        read -p "按 Enter 继续..."
    done
}

# 主函数
main() {
    show_banner
    
    while true; do
        show_menu
        read -p "请选择 [1-8]: " choice
        echo ""
        
        case $choice in
            1)
                echo "🚀 开始完整安装开发环境..."
                echo ""
                if [ -f "./server-setup.sh" ]; then
                    ./server-setup.sh
                else
                    red "❌ 安装脚本不存在: server-setup.sh"
                fi
                ;;
            2)
                echo "🌐 开始安装 Clash 代理..."
                echo ""
                if [ -f "./clash-install.sh" ]; then
                    ./clash-install.sh
                else
                    red "❌ Clash 安装脚本不存在: clash-install.sh"
                fi
                ;;
            3)
                run_system_check
                ;;
            4)
                echo "📚 查看安装文档..."
                if [ -f "./README.md" ]; then
                    if command -v less &> /dev/null; then
                        less README.md
                    else
                        cat README.md
                    fi
                else
                    red "❌ 文档不存在: README.md"
                fi
                ;;
            5)
                echo "🔧 查看故障排除指南..."
                if [ -f "./troubleshooting.md" ]; then
                    if command -v less &> /dev/null; then
                        less troubleshooting.md
                    else
                        cat troubleshooting.md
                    fi
                else
                    red "❌ 故障排除指南不存在: troubleshooting.md"
                fi
                ;;
            6)
                echo "📱 查看 iTerm2 配置指南..."
                if [ -f "./iterm2-setup.md" ]; then
                    if command -v less &> /dev/null; then
                        less iterm2-setup.md
                    else
                        cat iterm2-setup.md
                    fi
                else
                    red "❌ iTerm2 指南不存在: iterm2-setup.md"
                fi
                ;;
            7)
                run_specific_script
                ;;
            8)
                echo "👋 退出"
                exit 0
                ;;
            *)
                red "❌ 无效选择，请输入 1-8"
                ;;
        esac
        
        if [ "$choice" != "3" ] && [ "$choice" != "7" ]; then
            echo ""
            read -p "按 Enter 返回主菜单..."
        fi
        
        echo ""
    done
}

# 运行主函数
main "$@"