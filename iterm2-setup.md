# iTerm2 + SSH 完整配置指南

## 🔑 SSH 密钥配置

### 1. 在 macOS 上生成 SSH 密钥

```bash
# 生成 ED25519 密钥（推荐）
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/ubuntu-dev

# 或生成 RSA 密钥（兼容性更好）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/ubuntu-dev
```

### 2. 复制公钥到服务器

```bash
# 方法1: 使用 ssh-copy-id
ssh-copy-id -i ~/.ssh/ubuntu-dev.pub user@your-server-ip

# 方法2: 手动复制
cat ~/.ssh/ubuntu-dev.pub | ssh user@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"
```

### 3. 配置 SSH 客户端

编辑 `~/.ssh/config`:

```bash
# Ubuntu 开发服务器
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
    LocalForward 8080 localhost:8080  # 其他应用
    LocalForward 5432 localhost:5432  # PostgreSQL
    LocalForward 3306 localhost:3306  # MySQL
    LocalForward 6379 localhost:6379  # Redis

# 生产服务器（如果有）
Host production
    HostName prod-server-ip
    User deploy
    Port 22
    IdentityFile ~/.ssh/production
    ServerAliveInterval 30
    # 生产环境建议不开启 ForwardAgent
    ForwardAgent no
```

## 🖥️ iTerm2 配置

### 1. 安装 iTerm2

```bash
# 使用 Homebrew 安装
brew install --cask iterm2

# 或从官网下载
# https://iterm2.com/
```

### 2. 安装 Nerd Fonts

```bash
# 安装字体
brew tap homebrew/cask-fonts

# 推荐字体（选择一个）
brew install --cask font-meslo-lg-nerd-font          # PowerLevel10k 推荐
brew install --cask font-fira-code-nerd-font         # 编程友好
brew install --cask font-jetbrains-mono-nerd-font    # JetBrains 出品
brew install --cask font-hack-nerd-font              # 清晰易读
brew install --cask font-source-code-pro             # Adobe 出品
```

### 3. 创建服务器 Profile

#### 在 iTerm2 中：

1. **打开 Preferences** (⌘,)
2. **选择 Profiles 标签**
3. **点击 + 创建新 Profile**
4. **命名为 "Ubuntu Dev Server"**

#### General 配置：
- **Name**: Ubuntu Dev Server
- **Command**: 选择 "Command"
- **Command**: `ssh ubuntu-dev`
- **Working Directory**: "Reuse previous session's directory"
- **Icon**: 可选择 Ubuntu 图标

#### Colors 配置：
- **Color Presets**: 选择 "Solarized Dark" 或 "Tomorrow Night"
- 或导入自定义配色方案

#### Text 配置：
- **Font**: 选择 Nerd Font (如 "MesloLGS NF")
- **Size**: 14 或根据喜好调整
- **Use ligatures**: 启用（如果字体支持）
- **Anti-aliased**: 启用

#### Keys 配置：
添加常用快捷键：
- **⌘+T**: New Tab
- **⌘+W**: Close Tab  
- **⌘+←/→**: Previous/Next Tab
- **⌘+D**: Split Vertically
- **⌘+Shift+D**: Split Horizontally

#### Terminal 配置：
- **Scrollback lines**: 10000
- **Save lines to scrollback when an app status bar is present**: 启用

### 4. 高级配置

#### 状态栏配置：
1. **Session → Configure Status Bar**
2. **添加组件**：
   - CPU Utilization
   - Memory Utilization
   - Network Throughput
   - Current Directory
   - Git State
   - Clock

#### 自动化配置：
```bash
# 创建连接脚本
cat > ~/bin/connect-dev.sh << 'EOF'
#!/bin/bash
# 快速连接开发服务器

SERVER="ubuntu-dev"

# 检查服务器是否可达
if ping -c 1 $(ssh -G $SERVER | grep '^hostname ' | cut -d' ' -f2) &> /dev/null; then
    echo "🚀 连接到开发服务器..."
    ssh $SERVER
else
    echo "❌ 服务器不可达，请检查网络连接"
    exit 1
fi
EOF

chmod +x ~/bin/connect-dev.sh
```

## 🔧 VS Code Remote 集成

### 1. 安装扩展

```bash
# 在 VS Code 中安装
Remote - SSH
Remote - SSH: Editing Configuration Files
Remote - Containers (可选)
```

### 2. 配置 Remote SSH

1. **Command Palette** (⌘+Shift+P)
2. **Remote-SSH: Connect to Host**
3. **选择 "ubuntu-dev"**
4. **首次连接会安装 VS Code Server**

### 3. 工作区配置

在服务器上创建项目工作区：

```json
// ~/.vscode-server/data/User/settings.json
{
    "terminal.integrated.shell.linux": "/usr/bin/zsh",
    "terminal.integrated.fontFamily": "MesloLGS NF",
    "git.enableSmartCommit": true,
    "editor.formatOnSave": true,
    "files.autoSave": "afterDelay",
    "extensions.autoUpdate": false
}
```

## 📱 移动端访问

### Termius (iOS/Android)

1. **下载 Termius 应用**
2. **添加新主机**：
   - Address: your-server-ip
   - Username: your-username
   - Port: 22
3. **导入 SSH 密钥或使用密码**
4. **配置端口转发** (Termius Pro)

### Blink Shell (iOS)

```bash
# 在 Blink 中配置
config

# 添加主机
host ubuntu-dev
    hostname your-server-ip
    user your-username
    port 22
    identityfile ubuntu-dev
```

## 🛠️ 开发工作流

### 1. 本地开发 + 远程执行

```bash
# 同步代码到服务器
rsync -avz --exclude 'node_modules' --exclude '.git' \
  ./my-project/ ubuntu-dev:~/projects/my-project/

# 在服务器上执行
ssh ubuntu-dev "cd ~/projects/my-project && npm install && npm run build"
```

### 2. 远程开发 + 本地预览

```bash
# 在服务器上启动开发服务器
ssh ubuntu-dev "cd ~/projects/my-project && npm run dev"

# 通过端口转发在本地访问
# http://localhost:3000
```

### 3. 代码同步脚本

```bash
# 创建同步脚本
cat > ~/bin/sync-project.sh << 'EOF'
#!/bin/bash

PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo "用法: $0 <项目名>"
    exit 1
fi

LOCAL_PATH="./$PROJECT_NAME/"
REMOTE_PATH="ubuntu-dev:~/projects/$PROJECT_NAME/"

# 同步到服务器
echo "📤 同步到服务器..."
rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude 'dist' \
    --exclude '.DS_Store' \
    "$LOCAL_PATH" "$REMOTE_PATH"

echo "✅ 同步完成"
EOF

chmod +x ~/bin/sync-project.sh
```

## 🔐 安全最佳实践

### 1. SSH 密钥管理

```bash
# 定期轮换密钥 (建议每年)
ssh-keygen -t ed25519 -C "$(date +%Y)-key" -f ~/.ssh/ubuntu-dev-$(date +%Y)

# 使用 SSH Agent
ssh-add ~/.ssh/ubuntu-dev

# 检查已加载的密钥
ssh-add -l
```

### 2. 连接监控

```bash
# 在服务器上监控 SSH 连接
sudo tail -f /var/log/auth.log | grep ssh

# 查看当前连接
who
w
```

### 3. 安全配置

在服务器上的 `/etc/ssh/sshd_config`:

```bash
# 安全建议
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

## 📞 故障排除

### 常见问题

1. **连接超时**
```bash
# 检查网络连接
ping your-server-ip

# 检查端口
nmap -p 22 your-server-ip

# 详细连接信息
ssh -v ubuntu-dev
```

2. **密钥认证失败**
```bash
# 检查密钥权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ubuntu-dev
chmod 644 ~/.ssh/ubuntu-dev.pub

# 检查服务器上的 authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

3. **端口转发不工作**
```bash
# 检查端口是否被占用
lsof -i :9090

# 测试端口转发
ssh -L 9090:localhost:9090 ubuntu-dev
```

4. **字体显示问题**
```bash
# 确认字体已安装
fc-list | grep -i nerd

# 在 iTerm2 中选择正确字体
```

### 调试工具

```bash
# SSH 连接调试
ssh -vvv ubuntu-dev

# 网络诊断
mtr your-server-ip

# 端口扫描
nmap -p 1-65535 your-server-ip
```

## 🎨 个性化配置

### iTerm2 主题

```bash
# 下载流行主题
git clone https://github.com/mbadolato/iTerm2-Color-Schemes.git
cd iTerm2-Color-Schemes

# 导入到 iTerm2
# Preferences → Profiles → Colors → Color Presets → Import
```

### 终端美化

在服务器上配置 PowerLevel10k：

```bash
# 首次连接后运行
p10k configure

# 推荐配置选项
# 1. Does this look like a diamond? → y
# 2. Does this look like a lock? → y
# 3. Does this look like a Debian logo? → y
# 4. Do these icons fit between the crosses? → y
# 5. Prompt Style → (3) Rainbow
# 6. Character Set → (1) Unicode
# 7. Show current time? → (2) 24-hour format
# 8. Prompt Separators → (1) Angled
# 9. Prompt Heads → (1) Sharp
# 10. Prompt Tails → (1) Flat
# 11. Prompt Height → (2) Two lines
# 12. Prompt Connection → (2) Dotted
# 13. Prompt Frame → (4) Full
# 14. Connection & Frame Color → (2) Light
# 15. Prompt Spacing → (2) Sparse
# 16. Icons → (2) Many icons
# 17. Prompt Flow → (1) Concise
# 18. Enable Transient Prompt? → (y) Yes
# 19. Instant Prompt Mode → (1) Verbose
```

---

**配置完成后，您将拥有一个完美的远程开发环境！** 🎉