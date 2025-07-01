#!/bin/bash

# Ubuntu Server 开发环境完整配置脚本
# 版本: v1.0
# 支持: Ubuntu 24.04 LTS
# 作者: AI Assistant

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
    cyan "🚀 Ubuntu Server 开发环境配置"
    cyan "=================================="
    echo ""
    green "支持系统: Ubuntu 24.04 LTS"
    green "配置内容: 开发工具 + 编程环境 + 安全配置"
    green "预计时间: 10-15 分钟"
    echo ""
}

# 检查系统要求
check_system() {
    yellow "🔍 检查系统环境..."
    
    # 检查是否为 Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        red "❌ 此脚本仅支持 Ubuntu 系统"
        exit 1
    fi
    
    # 检查版本
    VERSION=$(lsb_release -rs)
    if [[ $(echo "$VERSION >= 20.04" | bc -l) -ne 1 ]]; then
        yellow "⚠️  推荐使用 Ubuntu 20.04 或更新版本"
    fi
    
    # 检查权限
    if [[ $EUID -eq 0 ]]; then
        red "❌ 请不要以 root 用户运行此脚本"
        exit 1
    fi
    
    # 检查 sudo 权限
    if ! sudo -n true 2>/dev/null; then
        yellow "⚠️  此脚本需要 sudo 权限"
        echo "请确保您的用户在 sudoers 组中"
    fi
    
    green "✅ 系统检查通过"
}

# 修复 APT 源
fix_apt_sources() {
    green "📦 1. 修复和更新 APT 源..."
    
    # 检查并修复 sources.list
    CODENAME=$(lsb_release -cs)
    
    if [ "$CODENAME" = "noble" ]; then
        yellow "检测到 Ubuntu 24.04，配置官方源..."
        
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup 2>/dev/null || true
        
        sudo tee /etc/apt/sources.list << 'EOF'
# Ubuntu 24.04 LTS (Noble Numbat) 官方源
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF
    fi
    
    # 临时禁用代理更新
    yellow "更新软件包列表..."
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt update
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt upgrade -y
    
    green "✅ 系统更新完成"
}

# 安装基础工具
install_essential_tools() {
    green "🛠️  2. 安装基础开发工具..."
    
    # 基础工具包
    local packages=(
        # 编译工具
        "build-essential"
        "git"
        "curl"
        "wget"
        "unzip"
        "tar"
        "gzip"
        
        # 编辑器
        "vim"
        "nano"
        
        # 系统工具
        "htop"
        "tree"
        "jq"
        "tmux"
        "screen"
        "ncdu"
        "fd-find"
        "ripgrep"
        "bat"
        "fzf"
        
        # Shell
        "zsh"
        
        # 网络安全
        "openssh-server"
        "fail2ban"
        "ufw"
        
        # 系统库
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "software-properties-common"
        "apt-transport-https"
    )
    
    yellow "安装软件包..."
    for package in "${packages[@]}"; do
        if sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y "$package"; then
            echo "  ✅ $package"
        else
            echo "  ⚠️  $package (跳过)"
        fi
    done
    
    # 尝试安装 eza (现代化的 ls)
    if sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y eza 2>/dev/null; then
        echo "  ✅ eza"
    else
        yellow "  ⚠️  eza 不可用，将使用传统命令"
    fi
    
    green "✅ 基础工具安装完成"
}

# 配置 Zsh 和 Oh-My-Zsh
setup_zsh() {
    green "🐚 3. 配置 Zsh 和 Oh-My-Zsh..."
    
    # 安装 Oh-My-Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        yellow "安装 Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # 安装插件
    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "powerlevel10k:https://github.com/romkatv/powerlevel10k.git"
    )
    
    for plugin_info in "${plugins[@]}"; do
        local plugin_name=$(echo $plugin_info | cut -d: -f1)
        local plugin_url=$(echo $plugin_info | cut -d: -f2-)
        local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/$plugin_name"
        
        if [ "$plugin_name" = "powerlevel10k" ]; then
            plugin_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
        fi
        
        if [ ! -d "$plugin_dir" ]; then
            yellow "安装 $plugin_name..."
            git clone --depth=1 "$plugin_url" "$plugin_dir"
        fi
    done
    
    # 创建 .zshrc 配置文件
    cp "$(dirname "$0")/configs/.zshrc" "$HOME/.zshrc" 2>/dev/null || cat > "$HOME/.zshrc" << 'EOF'
# Oh-My-Zsh 配置
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件
plugins=(
    git
    docker
    docker-compose
    kubectl
    node
    npm
    python
    pip
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    sudo
    extract
    z
)

source $ZSH/oh-my-zsh.sh

# 现代化别名
if command -v eza &> /dev/null; then
    alias ll='eza -la --icons'
    alias la='eza -la --icons'
    alias ls='eza --icons'
    alias tree='eza --tree --icons'
else
    alias ll='ls -la'
    alias la='ls -la'
fi

if command -v batcat &> /dev/null; then
    alias cat='batcat'
    alias bat='batcat'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# 系统别名
alias top='htop'
alias df='df -h'
alias free='free -h'
alias du='ncdu'
alias mkdir='mkdir -pv'
alias ping='ping -c 5'
alias ..='cd ..'
alias ...='cd ../..'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# 环境变量
export EDITOR=vim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 路径配置
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# 代理设置（如果 Clash 可用）
if systemctl is-active --quiet mihomo 2>/dev/null; then
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local
fi

# 代理管理函数
proxy_on() {
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    echo "✅ 代理已开启"
}

proxy_off() {
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    echo "✅ 代理已关闭"
}

proxy_test() {
    if [ -n "$HTTP_PROXY" ]; then
        echo "当前代理: $HTTP_PROXY"
        curl -x "$HTTP_PROXY" --connect-timeout 5 http://ifconfig.me 2>/dev/null || echo "代理连接失败"
    else
        echo "未设置代理"
    fi
}

# Python 虚拟环境
alias activate-default='source $HOME/venv/default/bin/activate 2>/dev/null || echo "请先创建默认虚拟环境: python3 -m venv $HOME/venv/default"'
alias mk-venv='python3 -m venv'

# Docker 别名
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'

# 系统信息函数
sysinfo() {
    echo "════════════════════════════════════"
    echo "🖥️  系统信息"
    echo "════════════════════════════════════"
    echo "系统: $(lsb_release -d | cut -f2)"
    echo "内核: $(uname -r)"
    echo "运行时间: $(uptime -p)"
    echo "负载: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "💾 内存使用:"
    free -h
    echo ""
    echo "💿 磁盘使用:"
    df -h /
}

# 有用的函数
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' 无法解压" ;;
        esac
    else
        echo "'$1' 不是有效文件"
    fi
}

# 网络工具
port-check() {
    if [ $# -eq 0 ]; then
        echo "用法: port-check <端口号>"
        return 1
    fi
    netstat -tuln | grep ":$1 " || echo "端口 $1 未监听"
}

# 显示欢迎信息
if [ -f "$HOME/.welcome" ]; then
    cat "$HOME/.welcome"
fi
EOF
    
    # 设置 zsh 为默认 shell
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        yellow "设置 zsh 为默认 shell..."
        chsh -s /usr/bin/zsh
    fi
    
    green "✅ Zsh 配置完成"
}

# 安装 Node.js 环境
install_nodejs() {
    green "🌐 4. 安装 Node.js 环境..."
    
    # 添加 NodeSource 仓库
    yellow "添加 NodeSource 仓库..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    
    # 安装 Node.js
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y nodejs
    
    # 配置 npm 代理（如果有）
    if systemctl is-active --quiet mihomo 2>/dev/null; then
        npm config set proxy http://127.0.0.1:7890
        npm config set https-proxy http://127.0.0.1:7890
        npm config set registry https://registry.npmjs.org/
    fi
    
    # 安装现代化全局包
    yellow "安装全局包..."
    local npm_packages=(
        "yarn"
        "pnpm"
        "pm2"
        "nodemon"
        "typescript"
        "@types/node"
        "tsx"
        "vite"
        "create-vite"
        "@vue/cli@latest"
        "create-react-app@latest"
        "express-generator@latest"
        "@nestjs/cli"
    )
    
    for package in "${npm_packages[@]}"; do
        if npm install -g "$package" 2>/dev/null; then
            echo "  ✅ $package"
        else
            echo "  ⚠️  $package (跳过)"
        fi
    done
    
    green "✅ Node.js 环境安装完成"
}

# 配置 Python 环境
setup_python() {
    green "🐍 5. 配置 Python 环境..."
    
    # 安装 Python 相关包
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        pipx
    
    # 确保 pipx 路径
    pipx ensurepath 2>/dev/null || true
    
    # 使用 pipx 安装全局工具
    yellow "安装 Python 全局工具..."
    local python_tools=(
        "poetry"
        "black"
        "flake8"
        "mypy"
        "jupyter"
        "httpie"
        "tldr"
        "rich-cli"
    )
    
    for tool in "${python_tools[@]}"; do
        if pipx install "$tool" 2>/dev/null; then
            echo "  ✅ $tool"
        else
            echo "  ⚠️  $tool (跳过)"
        fi
    done
    
    # 创建默认虚拟环境
    yellow "创建默认虚拟环境..."
    mkdir -p "$HOME/venv"
    if [ ! -d "$HOME/venv/default" ]; then
        python3 -m venv "$HOME/venv/default"
        source "$HOME/venv/default/bin/activate"
        pip install --upgrade pip
        pip install requests flask django fastapi uvicorn numpy pandas matplotlib ipython
        deactivate
    fi
    
    green "✅ Python 环境配置完成"
}

# 安装 Go 语言
install_go() {
    green "🔧 6. 安装 Go 语言..."
    
    GO_VERSION="1.21.5"
    yellow "下载 Go $GO_VERSION..."
    
    # 下载 Go
    if [ ! -f "/tmp/go.tar.gz" ]; then
        wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
    fi
    
    # 安装 Go
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    
    # 创建 GOPATH
    mkdir -p "$HOME/go/{bin,src,pkg}"
    
    green "✅ Go 语言安装完成"
}

# 安装 Docker
install_docker() {
    green "🐳 7. 安装 Docker..."
    
    # 添加 Docker 官方 GPG 密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加 Docker 仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新并安装 Docker
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt update
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # 将用户添加到 docker 组
    sudo usermod -aG docker "$USER"
    
    # 启用 Docker 服务
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # 安装 Docker Compose
    if [ ! -f "/usr/local/bin/docker-compose" ]; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    green "✅ Docker 安装完成"
}

# 配置 Git
setup_git() {
    green "📝 8. 配置 Git..."
    
    # 复制配置文件或创建默认配置
    if [ -f "$(dirname "$0")/configs/.gitconfig" ]; then
        cp "$(dirname "$0")/configs/.gitconfig" "$HOME/.gitconfig"
    else
        cat > "$HOME/.gitconfig" << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = vim
    autocrlf = input
    safecrlf = true
    quotepath = false

[init]
    defaultBranch = main

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    ca = commit -a
    ps = push
    pl = pull
    lg = log --oneline --graph --decorate --all
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    tree = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

[color]
    ui = auto
    branch = auto
    diff = auto
    status = auto

[push]
    default = simple

[pull]
    rebase = false

[diff]
    tool = vimdiff

[merge]
    tool = vimdiff
EOF
    fi
    
    yellow "⚠️  请编辑 ~/.gitconfig 设置您的用户名和邮箱"
    green "✅ Git 配置完成"
}

# 配置 Vim
setup_vim() {
    green "📝 9. 配置 Vim..."
    
    # 安装 vim-plug
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    # 创建 .vimrc
    if [ -f "$(dirname "$0")/configs/.vimrc" ]; then
        cp "$(dirname "$0")/configs/.vimrc" "$HOME/.vimrc"
    else
        cat > "$HOME/.vimrc" << 'EOF'
" Vim 配置文件
set nocompatible
filetype off

" 插件管理
call plug#begin('~/.vim/plugged')

" 文件管理
Plug 'preservim/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'

" Git 集成
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" 语法高亮和自动补全
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dense-analysis/ale'

" 代码格式化
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }

" 主题
Plug 'morhetz/gruvbox'

call plug#end()

filetype plugin indent on

" 基础设置
set number                    " 显示行号
set relativenumber           " 显示相对行号
set cursorline              " 高亮当前行
set tabstop=4               " Tab 宽度
set shiftwidth=4            " 缩进宽度
set expandtab               " 使用空格代替 Tab
set autoindent              " 自动缩进
set smartindent             " 智能缩进
set hlsearch                " 高亮搜索结果
set incsearch               " 增量搜索
set ignorecase              " 搜索忽略大小写
set smartcase               " 智能大小写搜索
set wrap                    " 自动换行
set linebreak               " 在单词边界换行
set mouse=a                 " 启用鼠标
set clipboard=unnamedplus   " 使用系统剪贴板
set encoding=utf-8          " 使用 UTF-8 编码
set fileencoding=utf-8      " 文件编码
set backup                  " 启用备份
set backupdir=~/.vim/backup " 备份目录
set swapfile                " 启用交换文件
set directory=~/.vim/swap   " 交换文件目录
set undofile                " 启用撤销文件
set undodir=~/.vim/undo     " 撤销文件目录

" 创建必要的目录
if !isdirectory($HOME."/.vim/backup")
    call mkdir($HOME."/.vim/backup", "p")
endif
if !isdirectory($HOME."/.vim/swap")
    call mkdir($HOME."/.vim/swap", "p")
endif
if !isdirectory($HOME."/.vim/undo")
    call mkdir($HOME."/.vim/undo", "p")
endif

" 外观设置
syntax on                   " 语法高亮
set background=dark         " 深色背景
colorscheme gruvbox         " 主题

" 状态栏
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='gruvbox'

" 快捷键
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
nnoremap <C-p> :CtrlP<CR>

" Leader 键
let mapleader = ","

" 窗口管理
nnoremap <Leader>h <C-w>h
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k
nnoremap <Leader>l <C-w>l

" 文件操作
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>x :x<CR>

" 取消搜索高亮
nnoremap <Leader>/ :nohlsearch<CR>

" 自动命令
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
EOF
    fi
    
    green "✅ Vim 配置完成"
}

# 配置安全设置
setup_security() {
    green "🔒 10. 配置安全设置..."
    
    # 配置 UFW 防火墙
    yellow "配置防火墙..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 9090/tcp  # Clash Web UI
    
    # 启用防火墙
    echo "y" | sudo ufw enable
    
    # 配置 Fail2Ban
    yellow "配置 Fail2Ban..."
    sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF
    
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    
    # 配置自动更新
    yellow "配置自动安全更新..."
    sudo -E env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy apt install -y unattended-upgrades
    
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    
    sudo tee /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    
    green "✅ 安全配置完成"
}

# 创建有用的脚本
create_utility_scripts() {
    green "📋 11. 创建实用脚本..."
    
    # 系统监控脚本
    cat > "$HOME/system-monitor.sh" << 'EOF'
#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🖥️  系统监控面板"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 系统信息
echo "📋 系统信息:"
echo "  发行版: $(lsb_release -d | cut -f2)"
echo "  内核版本: $(uname -r)"
echo "  运行时间: $(uptime -p)"
echo "  当前用户: $(whoami)"
echo "  主机名: $(hostname)"
echo ""

# 负载信息
echo "⚡ 系统负载:"
echo "  平均负载: $(uptime | awk -F'load average:' '{print $2}')"
echo "  CPU 核心数: $(nproc)"
echo ""

# 内存信息
echo "💾 内存使用:"
free -h | grep -E "Mem|Swap"
echo ""

# 磁盘使用
echo "💿 磁盘使用:"
df -h | grep -E "^/dev/"
echo ""

# 网络连接
echo "🌐 网络连接:"
echo "  监听端口: $(ss -tuln | grep LISTEN | wc -l)"
echo "  活跃连接: $(ss -tu | grep ESTAB | wc -l)"
echo ""

# 进程信息
echo "🔄 进程信息:"
echo "  总进程数: $(ps aux | wc -l)"
echo "  僵尸进程: $(ps aux | grep -c '[Zz]ombie')"
echo ""

# 服务状态
echo "🛠️  关键服务状态:"
services=("ssh" "ufw" "fail2ban" "docker" "mihomo")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  ✅ $service"
    else
        echo "  ❌ $service"
    fi
done
echo ""

# 最近登录
echo "👥 最近登录:"
last | head -5
echo ""

echo "════════════════════════════════════════════════════════════════"
EOF
    chmod +x "$HOME/system-monitor.sh"
    
    # 代理管理脚本
    cat > "$HOME/proxy-manager.sh" << 'EOF'
#!/bin/bash

case "$1" in
    on)
        export HTTP_PROXY=http://127.0.0.1:7890
        export HTTPS_PROXY=http://127.0.0.1:7890
        export http_proxy=http://127.0.0.1:7890
        export https_proxy=http://127.0.0.1:7890
        echo "✅ 代理已开启"
        echo "HTTP_PROXY=$HTTP_PROXY"
        ;;
    off)
        unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
        echo "✅ 代理已关闭"
        ;;
    test)
        echo "🔍 测试代理连接..."
        if [ -n "$HTTP_PROXY" ]; then
            echo "当前代理: $HTTP_PROXY"
            echo "测试连接..."
            curl -x "$HTTP_PROXY" --connect-timeout 5 -s http://ifconfig.me || echo "❌ 代理连接失败"
        else
            echo "⚠️  未设置代理变量"
            echo "测试直连..."
            curl --connect-timeout 5 -s http://ifconfig.me || echo "❌ 网络连接失败"
        fi
        ;;
    status)
        echo "📊 代理状态:"
        if [ -n "$HTTP_PROXY" ]; then
            echo "  HTTP_PROXY: $HTTP_PROXY"
            echo "  HTTPS_PROXY: $HTTPS_PROXY"
        else
            echo "  代理变量: 未设置"
        fi
        
        if systemctl is-active --quiet mihomo 2>/dev/null; then
            echo "  Clash 服务: ✅ 运行中"
        else
            echo "  Clash 服务: ❌ 未运行"
        fi
        ;;
    *)
        echo "用法: $0 {on|off|test|status}"
        echo "  on     - 开启代理变量"
        echo "  off    - 关闭代理变量"
        echo "  test   - 测试代理连接"
        echo "  status - 查看代理状态"
        ;;
esac
EOF
    chmod +x "$HOME/proxy-manager.sh"
    
    # 开发环境管理脚本
    cat > "$HOME/dev-env-manager.sh" << 'EOF'
#!/bin/bash

show_versions() {
    echo "🌐 编程语言版本:"
    echo "────────────────────────────────────"
    
    if command -v node &> /dev/null; then
        echo "  Node.js: $(node --version)"
        echo "  npm: v$(npm --version)"
    else
        echo "  Node.js: ❌ 未安装"
    fi
    
    if command -v python3 &> /dev/null; then
        echo "  Python: $(python3 --version | cut -d' ' -f2)"
        if command -v pip3 &> /dev/null; then
            echo "  pip: $(pip3 --version | cut -d' ' -f2)"
        fi
    else
        echo "  Python: ❌ 未安装"
    fi
    
    if command -v go &> /dev/null; then
        echo "  Go: $(go version | cut -d' ' -f3)"
    else
        echo "  Go: ❌ 未安装"
    fi
    
    if command -v git &> /dev/null; then
        echo "  Git: $(git --version | cut -d' ' -f3)"
    else
        echo "  Git: ❌ 未安装"
    fi
    
    if command -v docker &> /dev/null; then
        echo "  Docker: $(docker --version | cut -d' ' -f3 | sed 's/,//')"
    else
        echo "  Docker: ❌ 未安装"
    fi
    echo ""
}

case "$1" in
    status)
        echo "📊 开发环境状态"
        echo "════════════════════════════════════════"
        show_versions
        
        echo "🐍 Python 虚拟环境:"
        echo "────────────────────────────────────"
        if [ -d "$HOME/venv" ]; then
            for venv in "$HOME/venv"/*; do
                if [ -d "$venv" ]; then
                    echo "  📁 $(basename "$venv")"
                fi
            done
        else
            echo "  ❌ 无虚拟环境"
        fi
        echo ""
        
        echo "🔧 全局工具:"
        echo "────────────────────────────────────"
        tools=("yarn" "pnpm" "pm2" "pipx" "poetry")
        for tool in "${tools[@]}"; do
            if command -v "$tool" &> /dev/null; then
                echo "  ✅ $tool"
            else
                echo "  ❌ $tool"
            fi
        done
        ;;
    update)
        echo "🔄 更新开发环境..."
        
        # 更新 npm 全局包
        if command -v npm &> /dev/null; then
            echo "更新 npm 全局包..."
            npm update -g
        fi
        
        # 更新 pipx 包
        if command -v pipx &> /dev/null; then
            echo "更新 pipx 包..."
            pipx upgrade-all
        fi
        
        echo "✅ 更新完成"
        ;;
    backup)
        BACKUP_DIR="$HOME/config-backup-$(date +%Y%m%d-%H%M%S)"
        echo "📦 备份配置文件到 $BACKUP_DIR..."
        
        mkdir -p "$BACKUP_DIR"
        
        # 备份配置文件
        configs=(".zshrc" ".vimrc" ".gitconfig" ".npmrc")
        for config in "${configs[@]}"; do
            if [ -f "$HOME/$config" ]; then
                cp "$HOME/$config" "$BACKUP_DIR/"
                echo "  ✅ $config"
            fi
        done
        
        echo "✅ 备份完成: $BACKUP_DIR"
        ;;
    *)
        echo "用法: $0 {status|update|backup}"
        echo "  status - 显示开发环境状态"
        echo "  update - 更新开发工具"
        echo "  backup - 备份配置文件"
        ;;
esac
EOF
    chmod +x "$HOME/dev-env-manager.sh"
    
    green "✅ 实用脚本创建完成"
}

# 创建欢迎信息
create_welcome() {
    cat > "$HOME/.welcome" << 'EOF'
════════════════════════════════════════════════════════════════════════════════
🚀 Ubuntu Server 开发环境
════════════════════════════════════════════════════════════════════════════════

🛠️  已安装工具:
  • Zsh + Oh-My-Zsh + PowerLevel10k 主题
  • Node.js (LTS) + npm/yarn/pnpm + 现代化包
  • Python 3 + pipx + 虚拟环境 + 常用工具
  • Go 语言完整环境
  • Docker + Docker Compose
  • Git + Vim 完整配置

🔧 常用命令:
  • sysinfo               - 系统信息快览
  • ./system-monitor.sh   - 详细系统监控
  • ./proxy-manager.sh    - 代理管理 (on/off/test/status)
  • ./dev-env-manager.sh  - 开发环境管理 (status/update/backup)
  • activate-default      - 激活默认 Python 虚拟环境
  • mk-venv <name>        - 创建新的 Python 虚拟环境

🌐 代理管理:
  • proxy_on/proxy_off   - 开启/关闭代理变量
  • proxy_test           - 测试代理连接
  • clashon/clashoff     - Clash 服务控制 (如已安装)

📦 包管理:
  • npm/yarn/pnpm        - Node.js 包管理
  • pipx install <tool>  - Python 全局工具
  • pip install <pkg>    - 虚拟环境内包 (需先激活)

🔒 安全特性:
  • UFW 防火墙已启用
  • Fail2Ban 防暴力破解
  • 自动安全更新
  • SSH 安全配置

💡 提示:
  • 运行 'p10k configure' 配置终端主题
  • 编辑 ~/.gitconfig 设置 Git 用户信息
  • 使用 ':PlugInstall' 在 Vim 中安装插件

════════════════════════════════════════════════════════════════════════════════
EOF
}

# 显示完成信息
show_completion() {
    clear
    echo ""
    cyan "════════════════════════════════════════════════════════════════"
    cyan "🎉 Ubuntu Server 开发环境配置完成！"
    cyan "════════════════════════════════════════════════════════════════"
    echo ""
    
    green "✅ 已完成的配置："
    echo "   🔧 系统更新和基础工具安装"
    echo "   🐚 Zsh + Oh-My-Zsh + PowerLevel10k"
    echo "   🌐 Node.js + npm/yarn/pnpm 环境"
    echo "   🐍 Python + pipx + 虚拟环境"
    echo "   🔧 Go 语言环境"
    echo "   🐳 Docker + Docker Compose"
    echo "   📝 Git + Vim 配置"
    echo "   🔒 安全配置 (UFW + Fail2Ban)"
    echo "   📋 实用脚本和别名"
    echo ""
    
    yellow "⚠️  重要提醒："
    echo "   1. 请重新登录以激活 Zsh 和所有配置"
    echo "   2. 运行 'p10k configure' 配置终端主题"
    echo "   3. 编辑 ~/.gitconfig 设置您的 Git 信息"
    echo "   4. Docker 组权限需要重新登录生效"
    echo "   5. 在 Vim 中运行 ':PlugInstall' 安装插件"
    echo ""
    
    blue "🚀 下一步建议："
    echo "   • 配置 SSH 密钥以便从本地连接"
    echo "   • 安装 Clash 代理 (可选): ./clash-install.sh"
    echo "   • 运行系统监控: ./system-monitor.sh"
    echo "   • 查看开发环境: ./dev-env-manager.sh status"
    echo ""
    
    green "📚 相关文档："
    echo "   • iTerm2 配置: 查看 iterm2-setup.md"
    echo "   • 开发指南: 查看 development-guide.md"
    echo "   • 故障排除: 查看 troubleshooting.md"
    echo ""
    
    cyan "════════════════════════════════════════════════════════════════"
    echo ""
    
    yellow "配置完成！重新登录以享受您的开发环境 🎯"
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
    check_system
    fix_apt_sources
    install_essential_tools
    setup_zsh
    install_nodejs
    setup_python
    install_go
    install_docker
    setup_git
    setup_vim
    setup_security
    create_utility_scripts
    create_welcome
    
    show_completion
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi