# Ubuntu Server 开发环境配置包

这是一个完整的 Ubuntu Server 24.04 LTS 开发环境配置包，包含了 Clash 代理、开发工具、编程环境等完整配置。

## 📦 包含内容

### 🚀 主要脚本
- `server-setup.sh` - 完整的服务器环境配置脚本
- `clash-install.sh` - Clash 代理安装和配置
- `fix-issues.sh` - 修复常见配置问题
- `system-monitor.sh` - 系统监控和信息脚本

### 🔧 工具脚本
- `proxy-manager.sh` - 代理管理工具
- `dev-env-manager.sh` - 开发环境管理
- `backup-config.sh` - 配置文件备份
- `security-hardening.sh` - 系统安全加固

### 📋 配置文件
- `.zshrc` - 优化的 Zsh 配置
- `.vimrc` - Vim 配置
- `.gitconfig` - Git 配置模板
- `docker-compose.yml` - 常用开发服务

### 📚 文档
- `iterm2-setup.md` - iTerm2 连接配置指南
- `development-guide.md` - 开发环境使用指南
- `troubleshooting.md` - 故障排除指南

## 🚀 快速开始

1. **上传配置包到服务器**
   ```bash
   scp -r server-config-pack/ user@server:~/
   ```

2. **执行主安装脚本**
   ```bash
   cd ~/server-config-pack
   chmod +x *.sh
   ./server-setup.sh
   ```

3. **可选：安装 Clash 代理**
   ```bash
   ./clash-install.sh
   ```

## 🛠️ 功能特性

### ✅ 开发环境
- Zsh + Oh-My-Zsh + PowerLevel10k
- Node.js (LTS) + npm/yarn/pnpm
- Python 3 + pipx + 虚拟环境
- Go 语言环境
- Docker + Docker Compose
- Git 配置

### ✅ 系统工具
- 现代化命令行工具 (eza, bat, fd, rg, htop)
- Vim 配置和插件
- tmux, screen 会话管理
- 系统监控工具

### ✅ 网络配置
- Clash 代理支持
- SSH 安全配置
- 防火墙配置
- 端口管理

### ✅ 安全特性
- Fail2ban 防暴力破解
- UFW 防火墙配置
- SSH 密钥认证
- 自动安全更新

## 📱 客户端配置

### iTerm2 (macOS)
详见 `iterm2-setup.md`

### SSH 配置
```bash
Host ubuntu-dev
    HostName YOUR_SERVER_IP
    User YOUR_USERNAME
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 9090 localhost:9090
```

## 🔧 维护命令

```bash
# 系统信息
./system-monitor.sh

# 代理管理
./proxy-manager.sh on|off|test

# 环境管理
./dev-env-manager.sh status|update|backup

# 备份配置
./backup-config.sh
```

## 📞 支持

如遇问题请查看 `troubleshooting.md` 或检查系统日志。

---

**作者**: Haotian Lyu  
**版本**: v1.0  
**支持系统**: Ubuntu 24.04 LTS  
**最后更新**: 2025-06-30