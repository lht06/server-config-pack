#!/bin/bash

# 服务器配置包打包和传输脚本
# 将配置包打包并传输到本地机器

set -e

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 配置变量
PACK_NAME="server-config-pack-$(date +%Y%m%d-%H%M%S)"
BASE_DIR="/home/haotian"
PACK_DIR="$BASE_DIR/server-config-pack"

echo "=================================="
blue "📦 服务器配置包打包工具"
echo "=================================="

# 检查目录是否存在
if [ ! -d "$PACK_DIR" ]; then
    red "❌ 配置包目录不存在: $PACK_DIR"
    exit 1
fi

# 创建打包目录结构
create_package_structure() {
    green "📁 创建配置包结构..."
    
    cd "$BASE_DIR"
    
    # 确保所有脚本可执行
    chmod +x "$PACK_DIR"/*.sh 2>/dev/null || true
    
    # 创建完整的目录结构
    mkdir -p "$PACK_DIR/configs"
    mkdir -p "$PACK_DIR/docs"
    mkdir -p "$PACK_DIR/scripts"
    mkdir -p "$PACK_DIR/examples"
    
    green "✅ 目录结构创建完成"
}

# 复制额外的配置文件和脚本
copy_additional_files() {
    green "📋 复制额外文件..."
    
    # 复制现有的脚本到 scripts 目录
    if [ -f "$BASE_DIR/system-monitor.sh" ]; then
        cp "$BASE_DIR/system-monitor.sh" "$PACK_DIR/scripts/"
    fi
    
    if [ -f "$BASE_DIR/proxy-manager.sh" ]; then
        cp "$BASE_DIR/proxy-manager.sh" "$PACK_DIR/scripts/"
    fi
    
    if [ -f "$BASE_DIR/dev-env-manager.sh" ]; then
        cp "$BASE_DIR/dev-env-manager.sh" "$PACK_DIR/scripts/"
    fi
    
    if [ -f "$BASE_DIR/clash-manager.sh" ]; then
        cp "$BASE_DIR/clash-manager.sh" "$PACK_DIR/scripts/"
    fi
    
    # 复制配置文件
    for config in .zshrc .vimrc .gitconfig; do
        if [ -f "$BASE_DIR/$config" ]; then
            cp "$BASE_DIR/$config" "$PACK_DIR/configs/"
        fi
    done
    
    green "✅ 文件复制完成"
}

# 创建示例文件
create_examples() {
    green "📝 创建示例文件..."
    
    # Docker Compose 示例
    cat > "$PACK_DIR/examples/docker-compose.yml" << 'EOF'
# 开发环境 Docker Compose 示例
version: '3.8'

services:
  # PostgreSQL 数据库
  postgres:
    image: postgres:15
    container_name: dev-postgres
    environment:
      POSTGRES_DB: devdb
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  # Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: dev-redis
    ports:
      - "6379:6379"
    restart: unless-stopped

  # Nginx 代理
  nginx:
    image: nginx:alpine
    container_name: dev-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    restart: unless-stopped

  # Node.js 应用示例
  app:
    build: .
    container_name: dev-app
    ports:
      - "3000:3000"
    volumes:
      - ./:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://dev:devpass@postgres:5432/devdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

volumes:
  postgres_data:
EOF

    # SSH 配置示例
    cat > "$PACK_DIR/examples/ssh-config-example" << 'EOF'
# SSH 配置示例 (~/.ssh/config)

# 开发服务器
Host ubuntu-dev
    HostName your-server-ip
    User your-username
    Port 22
    IdentityFile ~/.ssh/ubuntu-dev
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
    Compression yes
    # 端口转发
    LocalForward 9090 localhost:9090  # Clash Web UI
    LocalForward 3000 localhost:3000  # 开发服务器
    LocalForward 5432 localhost:5432  # PostgreSQL
    LocalForward 6379 localhost:6379  # Redis

# 生产服务器
Host production
    HostName prod-server-ip
    User deploy
    Port 22
    IdentityFile ~/.ssh/production
    ServerAliveInterval 30
    ForwardAgent no
    
# 跳板机配置
Host jumpserver
    HostName jump.example.com
    User jump-user
    Port 22
    IdentityFile ~/.ssh/jump-key

# 通过跳板机访问内网服务器
Host internal-server
    HostName 192.168.1.100
    User internal-user
    Port 22
    ProxyJump jumpserver
    IdentityFile ~/.ssh/internal-key
EOF

    # 开发环境变量示例
    cat > "$PACK_DIR/examples/env-example" << 'EOF'
# 开发环境变量示例 (.env)

# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
REDIS_URL=redis://localhost:6379

# API 配置
API_URL=http://localhost:3000
API_KEY=your-api-key-here

# 第三方服务
GITHUB_TOKEN=your-github-token
SLACK_WEBHOOK=your-slack-webhook

# 开发配置
NODE_ENV=development
LOG_LEVEL=debug
PORT=3000

# 代理配置
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
NO_PROXY=localhost,127.0.0.1,*.local
EOF

    green "✅ 示例文件创建完成"
}

# 创建快速启动脚本
create_quick_start() {
    cat > "$PACK_DIR/quick-start.sh" << 'EOF'
#!/bin/bash

# 服务器配置包快速启动脚本

echo "🚀 Ubuntu Server 开发环境配置包"
echo "=================================="
echo ""
echo "请选择要执行的操作:"
echo ""
echo "1) 完整安装开发环境"
echo "2) 仅安装 Clash 代理"
echo "3) 查看安装文档"
echo "4) 运行系统检查"
echo "5) 退出"
echo ""

read -p "请选择 [1-5]: " choice

case $choice in
    1)
        echo "开始完整安装..."
        ./server-setup.sh
        ;;
    2)
        echo "开始安装 Clash 代理..."
        ./clash-install.sh
        ;;
    3)
        echo "查看文档..."
        if command -v less &> /dev/null; then
            less README.md
        else
            cat README.md
        fi
        ;;
    4)
        echo "运行系统检查..."
        ./scripts/system-check.sh 2>/dev/null || echo "系统检查脚本不存在"
        ;;
    5)
        echo "退出"
        exit 0
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac
EOF
    chmod +x "$PACK_DIR/quick-start.sh"
}

# 创建故障排除文档
create_troubleshooting_docs() {
    cat > "$PACK_DIR/troubleshooting.md" << 'EOF'
# 故障排除指南

## 常见问题解决方案

### 1. APT 更新失败

**问题**: `apt update` 失败，显示签名错误或源不可用

**解决方案**:
```bash
# 临时禁用代理
sudo -E env -u HTTP_PROXY -u HTTPS_PROXY apt update

# 重置 APT 源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo tee /etc/apt/sources.list << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

sudo apt update
```

### 2. Node.js 包安装失败

**问题**: npm install 失败或包依赖问题

**解决方案**:
```bash
# 清理 npm 缓存
npm cache clean --force

# 使用官方源
npm config set registry https://registry.npmjs.org/

# 更新 npm
npm install -g npm@latest

# 重新安装
rm -rf node_modules package-lock.json
npm install
```

### 3. Python pip 安装问题

**问题**: pip install 失败，externally-managed-environment 错误

**解决方案**:
```bash
# 使用虚拟环境
python3 -m venv myenv
source myenv/bin/activate
pip install package-name

# 或使用 pipx 安装全局工具
pipx install package-name

# 或使用系统包管理
sudo apt install python3-package-name
```

### 4. Docker 权限问题

**问题**: 普通用户无法使用 docker 命令

**解决方案**:
```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或刷新组权限
newgrp docker

# 验证
docker ps
```

### 5. SSH 连接问题

**问题**: SSH 连接失败或频繁断开

**解决方案**:
```bash
# 检查 SSH 服务状态
sudo systemctl status ssh

# 重启 SSH 服务
sudo systemctl restart ssh

# 检查防火墙
sudo ufw status
sudo ufw allow ssh

# 客户端配置
# 在 ~/.ssh/config 添加:
ServerAliveInterval 60
ServerAliveCountMax 3
```

### 6. Clash 代理问题

**问题**: Clash 安装后无法访问外网

**解决方案**:
```bash
# 检查服务状态
sudo systemctl status mihomo

# 查看日志
sudo journalctl -u mihomo -f

# 检查端口
ss -tuln | grep -E "(7890|9090)"

# 测试代理
curl -x http://127.0.0.1:7890 http://ifconfig.me

# 手动选择节点
curl -X PUT http://127.0.0.1:9090/proxies/GLOBAL \
  -H "Content-Type: application/json" \
  -d '{"name": "节点名称"}'
```

### 7. Zsh 配置问题

**问题**: Zsh 主题或插件无法加载

**解决方案**:
```bash
# 重新安装 Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 安装插件
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 配置 PowerLevel10k
p10k configure

# 重新加载配置
source ~/.zshrc
```

### 8. 防火墙配置问题

**问题**: 服务无法从外部访问

**解决方案**:
```bash
# 检查 UFW 状态
sudo ufw status

# 开放端口
sudo ufw allow 9090/tcp comment 'Clash Web UI'
sudo ufw allow 3000/tcp comment 'Development Server'

# 重新加载规则
sudo ufw reload

# 检查云服务商安全组设置
```

### 9. 磁盘空间不足

**问题**: 系统提示磁盘空间不足

**解决方案**:
```bash
# 检查磁盘使用
df -h
du -sh /* | sort -hr | head -10

# 清理包缓存
sudo apt autoremove
sudo apt autoclean

# 清理 Docker
docker system prune -a

# 清理日志
sudo journalctl --vacuum-time=7d

# 清理临时文件
sudo rm -rf /tmp/*
```

### 10. 系统性能问题

**问题**: 系统运行缓慢或资源占用高

**解决方案**:
```bash
# 检查系统负载
htop
top

# 检查内存使用
free -h

# 检查磁盘 I/O
iotop

# 查找占用资源的进程
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head

# 重启占用资源的服务
sudo systemctl restart service-name
```

## 日志文件位置

- **系统日志**: `/var/log/syslog`
- **认证日志**: `/var/log/auth.log`
- **SSH 日志**: `/var/log/auth.log`
- **Docker 日志**: `docker logs container-name`
- **Systemd 日志**: `journalctl -u service-name`
- **Nginx 日志**: `/var/log/nginx/`
- **应用日志**: 通常在 `/var/log/app-name/`

## 紧急恢复

如果系统出现严重问题，可以尝试以下恢复步骤:

1. **安全模式启动**: 在 GRUB 菜单选择恢复模式
2. **网络恢复**: 使用云服务商的控制台访问
3. **备份恢复**: 从配置备份恢复重要文件
4. **重新安装**: 最后手段，重新运行配置脚本

## 获取帮助

- **Ubuntu 文档**: https://help.ubuntu.com/
- **Docker 文档**: https://docs.docker.com/
- **Git 文档**: https://git-scm.com/doc
- **Node.js 文档**: https://nodejs.org/docs/
- **Python 文档**: https://docs.python.org/
EOF

    green "✅ 故障排除文档创建完成"
}

# 生成版本信息
create_version_info() {
    cat > "$PACK_DIR/VERSION" << EOF
Server Config Pack Version Information
=====================================

Version: 1.0.0
Build Date: $(date '+%Y-%m-%d %H:%M:%S')
Build Host: $(hostname)
Build User: $(whoami)

Components:
- Ubuntu Server Setup Script
- Clash Proxy Installation
- Development Environment Configuration
- Docker Integration
- Security Hardening
- iTerm2 Connection Guide

Supported Systems:
- Ubuntu 24.04 LTS (Primary)
- Ubuntu 22.04 LTS (Compatible)
- Ubuntu 20.04 LTS (Compatible)

For updates and support:
https://github.com/your-repo/server-config-pack
EOF
}

# 打包配置
package_config() {
    green "📦 打包配置文件..."
    
    cd "$BASE_DIR"
    
    # 创建压缩包
    if command -v tar &> /dev/null; then
        yellow "使用 tar 打包..."
        tar -czf "${PACK_NAME}.tar.gz" -C . "$(basename "$PACK_DIR")"
        echo "  ✅ 创建了 ${PACK_NAME}.tar.gz"
    fi
    
    if command -v zip &> /dev/null; then
        yellow "使用 zip 打包..."
        zip -r "${PACK_NAME}.zip" "$(basename "$PACK_DIR")" > /dev/null
        echo "  ✅ 创建了 ${PACK_NAME}.zip"
    fi
    
    green "✅ 打包完成"
}

# 显示传输说明
show_transfer_instructions() {
    echo ""
    blue "=================================="
    blue "📤 传输到本地机器"
    blue "=================================="
    echo ""
    
    green "方法1: 使用 scp (推荐)"
    echo "在本地机器上运行:"
    echo "  scp user@server:$BASE_DIR/${PACK_NAME}.tar.gz ./"
    echo "  或"
    echo "  scp user@server:$BASE_DIR/${PACK_NAME}.zip ./"
    echo ""
    
    green "方法2: 使用 rsync"
    echo "在本地机器上运行:"
    echo "  rsync -avz user@server:$BASE_DIR/${PACK_NAME}.tar.gz ./"
    echo ""
    
    green "方法3: 通过 Web 服务器"
    echo "在服务器上运行:"
    echo "  cd $BASE_DIR"
    echo "  python3 -m http.server 8000"
    echo "然后在浏览器访问: http://server-ip:8000"
    echo ""
    
    green "文件信息:"
    if [ -f "${BASE_DIR}/${PACK_NAME}.tar.gz" ]; then
        local size=$(du -h "${BASE_DIR}/${PACK_NAME}.tar.gz" | cut -f1)
        echo "  📁 ${PACK_NAME}.tar.gz (${size})"
    fi
    
    if [ -f "${BASE_DIR}/${PACK_NAME}.zip" ]; then
        local size=$(du -h "${BASE_DIR}/${PACK_NAME}.zip" | cut -f1)
        echo "  📁 ${PACK_NAME}.zip (${size})"
    fi
    
    echo ""
    yellow "解压后使用:"
    echo "  tar -xzf ${PACK_NAME}.tar.gz"
    echo "  cd $(basename "$PACK_DIR")"
    echo "  ./quick-start.sh"
}

# 主函数
main() {
    create_package_structure
    copy_additional_files
    create_examples
    create_quick_start
    create_troubleshooting_docs
    create_version_info
    package_config
    show_transfer_instructions
    
    echo ""
    green "🎉 配置包打包完成！"
    echo ""
}

# 执行主函数
main "$@"