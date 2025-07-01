#!/bin/bash

# Clash 代理完整安装脚本
# 基于 clash-for-linux-install 项目优化
# 版本: v1.0

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }
cyan() { echo -e "\033[36m$1\033[0m"; }

# 显示横幅
show_banner() {
    clear
    cyan "=================================="
    cyan "🚀 Clash 代理安装配置"
    cyan "=================================="
    echo ""
    green "功能: 代理服务 + Web 管理 + Docker 代理"
    green "内核: mihomo (Clash 继任者)"
    green "预计时间: 5-10 分钟"
    echo ""
}

# 获取订阅地址
get_subscription() {
    echo ""
    yellow "请输入您的 Clash 订阅地址:"
    yellow "示例: https://example.com/api/v1/client/subscribe?token=xxx"
    echo -n "订阅地址: "
    read -r SUBSCRIPTION_URL
    
    if [ -z "$SUBSCRIPTION_URL" ]; then
        red "❌ 订阅地址不能为空"
        exit 1
    fi
    
    green "✅ 订阅地址: $SUBSCRIPTION_URL"
}

# 检查系统环境
check_environment() {
    green "🔍 检查系统环境..."
    
    # 检查是否为 root
    if [[ $EUID -eq 0 ]]; then
        red "❌ 请不要以 root 用户运行此脚本"
        exit 1
    fi
    
    # 检查 sudo 权限
    if ! sudo -n true 2>/dev/null; then
        yellow "⚠️  此脚本需要 sudo 权限"
    fi
    
    # 检查是否已安装
    if systemctl is-active --quiet mihomo 2>/dev/null; then
        yellow "⚠️  检测到 mihomo 服务已运行"
        echo -n "是否重新安装? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "安装取消"
            exit 0
        fi
    fi
    
    green "✅ 环境检查通过"
}

# 使用官方安装脚本
install_using_official() {
    green "📦 使用官方 clash-for-linux-install..."
    
    # 临时目录
    TEMP_DIR="/tmp/clash-install-$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # 下载官方安装包
    yellow "下载官方安装包..."
    if ! wget -q -O clash-install.zip https://github.com/nelvko/clash-for-linux-install/archive/refs/heads/master.zip; then
        red "❌ 下载失败，尝试使用代理..."
        export HTTP_PROXY=http://127.0.0.1:7890
        export HTTPS_PROXY=http://127.0.0.1:7890
        wget -O clash-install.zip https://github.com/nelvko/clash-for-linux-install/archive/refs/heads/master.zip
    fi
    
    # 解压
    unzip -q clash-install.zip
    cd clash-for-linux-install-master
    
    # 执行安装
    yellow "执行官方安装脚本..."
    echo "$SUBSCRIPTION_URL" | sudo bash install.sh
    
    # 清理
    cd "$HOME"
    rm -rf "$TEMP_DIR"
    
    green "✅ 官方安装完成"
}

# 手动安装方法（备用）
install_manually() {
    green "🔧 手动安装 Clash..."
    
    # 创建目录
    sudo mkdir -p /opt/clash /etc/clash
    
    # 下载 mihomo 核心
    yellow "下载 mihomo 核心..."
    MIHOMO_VERSION="v1.18.8"
    wget -O /tmp/mihomo.gz "https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-amd64-${MIHOMO_VERSION}.gz"
    gunzip /tmp/mihomo.gz
    sudo mv /tmp/mihomo /usr/local/bin/clash
    sudo chmod +x /usr/local/bin/clash
    
    # 下载配置
    yellow "下载订阅配置..."
    sudo wget -O /opt/clash/config.yaml "$SUBSCRIPTION_URL"
    
    # 创建 systemd 服务
    yellow "创建系统服务..."
    sudo tee /etc/systemd/system/mihomo.service << 'EOF'
[Unit]
Description=mihomo Daemon, A[nother] Clash Kernel.
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
User=root
ExecStart=/usr/local/bin/clash -d /opt/clash
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    
    # 启动服务
    sudo systemctl daemon-reload
    sudo systemctl enable mihomo
    sudo systemctl start mihomo
    
    green "✅ 手动安装完成"
}

# 配置 Docker 代理
setup_docker_proxy() {
    green "🐳 配置 Docker 代理..."
    
    # 创建 Docker 代理配置
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf << 'EOF'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local"
EOF
    
    # 重新加载配置
    sudo systemctl daemon-reload
    
    # 重启 Docker 服务
    if systemctl is-active --quiet docker; then
        yellow "重启 Docker 服务..."
        sudo systemctl restart docker
    fi
    
    green "✅ Docker 代理配置完成"
}

# 配置防火墙
setup_firewall() {
    green "🛡️  配置防火墙..."
    
    # 开放 Clash 管理端口
    sudo ufw allow 9090/tcp comment 'Clash Web UI'
    
    green "✅ 防火墙配置完成"
}

# 创建管理脚本
create_management_scripts() {
    green "📋 创建管理脚本..."
    
    # Clash 管理脚本
    cat > "$HOME/clash-manager.sh" << 'EOF'
#!/bin/bash

SERVICE_NAME="mihomo"
PROXY_PORT="7890"
WEB_PORT="9090"

case "$1" in
    start)
        sudo systemctl start $SERVICE_NAME
        echo "✅ Clash 服务已启动"
        ;;
    stop)
        sudo systemctl stop $SERVICE_NAME
        echo "✅ Clash 服务已停止"
        ;;
    restart)
        sudo systemctl restart $SERVICE_NAME
        echo "✅ Clash 服务已重启"
        ;;
    status)
        echo "📊 Clash 服务状态:"
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo "  服务状态: ✅ 运行中"
            echo "  代理地址: http://127.0.0.1:$PROXY_PORT"
            echo "  Web 界面: http://127.0.0.1:$WEB_PORT/ui"
        else
            echo "  服务状态: ❌ 未运行"
        fi
        
        echo ""
        echo "🔗 端口监听:"
        if ss -tuln | grep -q ":$PROXY_PORT"; then
            echo "  代理端口 $PROXY_PORT: ✅ 监听中"
        else
            echo "  代理端口 $PROXY_PORT: ❌ 未监听"
        fi
        
        if ss -tuln | grep -q ":$WEB_PORT"; then
            echo "  Web 端口 $WEB_PORT: ✅ 监听中"
        else
            echo "  Web 端口 $WEB_PORT: ❌ 未监听"
        fi
        ;;
    test)
        echo "🔍 测试代理连接..."
        
        # 测试直连
        echo "直连 IP:"
        DIRECT_IP=$(curl -s --connect-timeout 5 http://ifconfig.me 2>/dev/null || echo "获取失败")
        echo "  $DIRECT_IP"
        
        # 测试代理
        echo "代理 IP:"
        PROXY_IP=$(curl -x http://127.0.0.1:$PROXY_PORT -s --connect-timeout 5 http://ifconfig.me 2>/dev/null || echo "获取失败")
        echo "  $PROXY_IP"
        
        if [ "$DIRECT_IP" != "$PROXY_IP" ] && [ "$PROXY_IP" != "获取失败" ]; then
            echo "✅ 代理工作正常"
        else
            echo "⚠️  代理可能未生效"
        fi
        ;;
    logs)
        echo "📋 Clash 服务日志:"
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    update)
        echo "🔄 更新订阅配置..."
        if command -v clashupdate &> /dev/null; then
            clashupdate
        else
            echo "⚠️  请使用 Clash 内置命令更新"
        fi
        ;;
    ui)
        echo "🌐 Web 管理界面:"
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo "  本地访问: http://127.0.0.1:$WEB_PORT/ui"
            echo "  内网访问: http://$(hostname -I | awk '{print $1}'):$WEB_PORT/ui"
            
            # 获取公网 IP
            PUBLIC_IP=$(curl -s --connect-timeout 3 http://ifconfig.me 2>/dev/null || echo "unknown")
            if [ "$PUBLIC_IP" != "unknown" ]; then
                echo "  公网访问: http://$PUBLIC_IP:$WEB_PORT/ui"
            fi
        else
            echo "❌ Clash 服务未运行"
        fi
        ;;
    *)
        echo "Clash 管理脚本"
        echo ""
        echo "用法: $0 {start|stop|restart|status|test|logs|update|ui}"
        echo ""
        echo "命令说明:"
        echo "  start    - 启动 Clash 服务"
        echo "  stop     - 停止 Clash 服务"
        echo "  restart  - 重启 Clash 服务"
        echo "  status   - 查看服务状态"
        echo "  test     - 测试代理连接"
        echo "  logs     - 查看服务日志"
        echo "  update   - 更新订阅配置"
        echo "  ui       - 显示 Web 界面地址"
        ;;
esac
EOF
    chmod +x "$HOME/clash-manager.sh"
    
    # 节点选择脚本
    cat > "$HOME/clash-node-selector.sh" << 'EOF'
#!/bin/bash

API_URL="http://127.0.0.1:9090"

# 获取所有代理
get_proxies() {
    curl -s "$API_URL/proxies" | jq -r '.proxies | to_entries[] | "\(.key): \(.value.type)"'
}

# 获取代理组
get_proxy_groups() {
    curl -s "$API_URL/proxies" | jq -r '.proxies | to_entries[] | select(.value.type == "Selector" or .value.type == "URLTest") | .key'
}

# 选择节点
select_node() {
    local group="$1"
    local node="$2"
    
    curl -s -X PUT "$API_URL/proxies/$group" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$node\"}"
}

case "$1" in
    list)
        echo "📋 可用代理:"
        get_proxies
        ;;
    groups)
        echo "📋 代理组:"
        get_proxy_groups
        ;;
    select)
        if [ $# -ne 3 ]; then
            echo "用法: $0 select <代理组> <节点名>"
            exit 1
        fi
        
        GROUP="$2"
        NODE="$3"
        
        echo "🔄 选择节点: $GROUP -> $NODE"
        select_node "$GROUP" "$NODE"
        echo "✅ 节点选择完成"
        ;;
    sg)
        echo "🇸🇬 选择新加坡节点..."
        # 获取新加坡节点
        SG_NODE=$(curl -s "$API_URL/proxies" | jq -r '.proxies | to_entries[] | select(.value.name | test("(?i)(singapore|新加坡|狮城|SG)")) | .key' | head -1)
        if [ -n "$SG_NODE" ]; then
            select_node "GLOBAL" "$SG_NODE"
            echo "✅ 已选择新加坡节点: $SG_NODE"
        else
            echo "❌ 未找到新加坡节点"
        fi
        ;;
    us)
        echo "🇺🇸 选择美国节点..."
        # 获取美国节点
        US_NODE=$(curl -s "$API_URL/proxies" | jq -r '.proxies | to_entries[] | select(.value.name | test("(?i)(united.states|america|美国|US)")) | .key' | head -1)
        if [ -n "$US_NODE" ]; then
            select_node "GLOBAL" "$US_NODE"
            echo "✅ 已选择美国节点: $US_NODE"
        else
            echo "❌ 未找到美国节点"
        fi
        ;;
    *)
        echo "Clash 节点选择脚本"
        echo ""
        echo "用法: $0 {list|groups|select|sg|us}"
        echo ""
        echo "命令说明:"
        echo "  list            - 列出所有代理"
        echo "  groups          - 列出代理组"
        echo "  select <组> <节点> - 选择指定节点"
        echo "  sg              - 快速选择新加坡节点"
        echo "  us              - 快速选择美国节点"
        ;;
esac
EOF
    chmod +x "$HOME/clash-node-selector.sh"
    
    green "✅ 管理脚本创建完成"
}

# 验证安装
verify_installation() {
    green "🔍 验证安装..."
    
    sleep 3  # 等待服务启动
    
    # 检查服务状态
    if systemctl is-active --quiet mihomo; then
        echo "  ✅ Clash 服务运行正常"
    else
        echo "  ❌ Clash 服务未运行"
        return 1
    fi
    
    # 检查端口监听
    if ss -tuln | grep -q ":7890"; then
        echo "  ✅ 代理端口 7890 监听正常"
    else
        echo "  ❌ 代理端口 7890 未监听"
    fi
    
    if ss -tuln | grep -q ":9090"; then
        echo "  ✅ Web 端口 9090 监听正常"
    else
        echo "  ❌ Web 端口 9090 未监听"
    fi
    
    # 测试代理
    yellow "测试代理连接..."
    PROXY_IP=$(curl -x http://127.0.0.1:7890 -s --connect-timeout 10 http://ifconfig.me 2>/dev/null || echo "获取失败")
    if [ "$PROXY_IP" != "获取失败" ]; then
        echo "  ✅ 代理连接正常，出口 IP: $PROXY_IP"
    else
        echo "  ⚠️  代理连接失败，可能需要等待节点连接"
    fi
    
    green "✅ 安装验证完成"
}

# 显示完成信息
show_completion() {
    clear
    echo ""
    cyan "════════════════════════════════════════════════════════════════"
    cyan "🎉 Clash 代理安装完成！"
    cyan "════════════════════════════════════════════════════════════════"
    echo ""
    
    green "📋 服务信息:"
    echo "   🌐 代理地址: http://127.0.0.1:7890"
    echo "   🖥️  Web 界面: http://127.0.0.1:9090/ui"
    echo "   📁 配置目录: /opt/clash"
    echo "   🔧 服务名称: mihomo"
    echo ""
    
    green "🛠️  管理命令:"
    echo "   ./clash-manager.sh status    - 查看服务状态"
    echo "   ./clash-manager.sh test      - 测试代理连接"
    echo "   ./clash-manager.sh ui        - 显示 Web 界面"
    echo "   ./clash-node-selector.sh sg  - 选择新加坡节点"
    echo "   ./clash-node-selector.sh us  - 选择美国节点"
    echo ""
    
    green "🌐 代理设置:"
    echo "   export HTTP_PROXY=http://127.0.0.1:7890"
    echo "   export HTTPS_PROXY=http://127.0.0.1:7890"
    echo "   或使用: clashon (如果已配置)"
    echo ""
    
    yellow "💡 使用提示:"
    echo "   1. 访问 Web 界面选择节点和策略"
    echo "   2. 使用管理脚本快速操作"
    echo "   3. Docker 代理已自动配置"
    echo "   4. 防火墙已开放 9090 端口"
    echo ""
    
    blue "🔗 快速链接:"
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    echo "   本地: http://127.0.0.1:9090/ui"
    echo "   内网: http://$LOCAL_IP:9090/ui"
    
    PUBLIC_IP=$(curl -s --connect-timeout 3 http://ifconfig.me 2>/dev/null || echo "unknown")
    if [ "$PUBLIC_IP" != "unknown" ]; then
        echo "   公网: http://$PUBLIC_IP:9090/ui"
    fi
    echo ""
    
    cyan "════════════════════════════════════════════════════════════════"
    echo ""
    
    green "🎯 Clash 代理配置完成！享受您的代理服务！"
    echo ""
}

# 主函数
main() {
    show_banner
    
    # 检查是否为交互模式
    if [ -t 1 ]; then
        echo "按 Enter 继续安装，或 Ctrl+C 取消..."
        read -r
    fi
    
    # 执行安装步骤
    check_environment
    get_subscription
    
    # 尝试使用官方安装，如果失败则手动安装
    if install_using_official; then
        green "✅ 使用官方安装成功"
    else
        yellow "⚠️  官方安装失败，尝试手动安装..."
        install_manually
    fi
    
    setup_docker_proxy
    setup_firewall
    create_management_scripts
    verify_installation
    show_completion
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi