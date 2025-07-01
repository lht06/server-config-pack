# Oh-My-Zsh 配置文件
# 优化版本 - 包含所有现代化工具和别名

export ZSH="$HOME/.oh-my-zsh"

# 主题
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
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
    colored-man-pages
    command-not-found
    history-substring-search
)

# 加载 Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# 现代化别名配置
# ============================================================================

# ls 替代品 (eza)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --header'
    alias la='eza -la --icons --group-directories-first'
    alias lt='eza --tree --icons --level=2'
    alias l='eza -l --icons --group-directories-first'
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# cat 替代品 (bat)
if command -v batcat &> /dev/null; then
    alias cat='batcat'
    alias bat='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat'
fi

# find 替代品 (fd)
if command -v fd &> /dev/null; then
    alias find='fd'
fi

# grep 替代品 (ripgrep)
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# top 替代品
if command -v htop &> /dev/null; then
    alias top='htop'
fi

if command -v btop &> /dev/null; then
    alias htop='btop'
    alias top='btop'
fi

# ============================================================================
# 系统别名
# ============================================================================

# 目录操作
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# 文件操作
alias mkdir='mkdir -pv'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ln='ln -i'

# 系统信息
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias ping='ping -c 5'

# 网络
alias ports='netstat -tulanp'
alias listening='lsof -i -P | grep LISTEN'
alias wget='wget -c'

# 权限
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# ============================================================================
# Git 别名
# ============================================================================

alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gba='git branch -a'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git remote'
alias grv='git remote -v'
alias gf='git fetch'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# ============================================================================
# Docker 别名
# ============================================================================

alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
alias dprune='docker system prune -a'

# ============================================================================
# 开发别名
# ============================================================================

# Node.js
alias ni='npm install'
alias nig='npm install -g'
alias nu='npm uninstall'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nd='npm run dev'

# Python
alias py='python3'
alias pip='pip3'
alias activate='source ./venv/bin/activate'
alias mkvenv='python3 -m venv'

# 虚拟环境快捷方式
alias activate-default='source $HOME/venv/default/bin/activate 2>/dev/null || echo "请先创建默认虚拟环境: python3 -m venv $HOME/venv/default"'

# Yarn
alias y='yarn'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yr='yarn remove'
alias ys='yarn start'
alias yb='yarn build'
alias yt='yarn test'

# ============================================================================
# 环境变量
# ============================================================================

# 编辑器
export EDITOR='vim'
export VISUAL='vim'

# 语言设置
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# 历史设置
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# ============================================================================
# 路径配置
# ============================================================================

# 本地 bin
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Go 语言
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Node.js (如果使用 nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Rust (如果安装)
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ============================================================================
# 代理配置
# ============================================================================

# 自动检测 Clash 服务并设置代理
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
    export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local
    export no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.local
    echo "✅ 代理已开启 (http://127.0.0.1:7890)"
}

proxy_off() {
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
    echo "✅ 代理已关闭"
}

proxy_test() {
    if [ -n "$HTTP_PROXY" ]; then
        echo "🔍 当前代理: $HTTP_PROXY"
        echo "🌐 测试连接..."
        local result=$(curl -x "$HTTP_PROXY" --connect-timeout 5 -s http://ifconfig.me 2>/dev/null || echo "连接失败")
        echo "📍 代理 IP: $result"
    else
        echo "⚠️  未设置代理"
        echo "🌐 测试直连..."
        local result=$(curl --connect-timeout 5 -s http://ifconfig.me 2>/dev/null || echo "连接失败")
        echo "📍 直连 IP: $result"
    fi
}

proxy_status() {
    echo "📊 代理状态:"
    if [ -n "$HTTP_PROXY" ]; then
        echo "  HTTP_PROXY: $HTTP_PROXY"
        echo "  HTTPS_PROXY: $HTTPS_PROXY"
        echo "  NO_PROXY: $NO_PROXY"
    else
        echo "  代理变量: ❌ 未设置"
    fi
    
    if systemctl is-active --quiet mihomo 2>/dev/null; then
        echo "  Clash 服务: ✅ 运行中"
    else
        echo "  Clash 服务: ❌ 未运行"
    fi
}

# ============================================================================
# 实用函数
# ============================================================================

# 创建目录并进入
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 解压函数
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        tar xf "$1"      ;;
            *)           echo "'$1' 无法解压" ;;
        esac
    else
        echo "'$1' 不是有效文件"
    fi
}

# 查找进程
psgrep() {
    ps aux | grep -v grep | grep "$@" -i --color=auto
}

# 杀死进程
killps() {
    local pid
    pid=$(ps -ef | grep "$1" | grep -v grep | awk '{print $2}')
    if [ -n "$pid" ]; then
        kill -9 "$pid"
        echo "已杀死进程: $1 (PID: $pid)"
    else
        echo "未找到进程: $1"
    fi
}

# 端口检查
port_check() {
    if [ $# -eq 0 ]; then
        echo "用法: port_check <端口号>"
        return 1
    fi
    
    local port="$1"
    if netstat -tuln | grep -q ":$port "; then
        echo "✅ 端口 $port 正在监听"
        netstat -tuln | grep ":$port "
    else
        echo "❌ 端口 $port 未监听"
    fi
}

# 快速备份
backup() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d-%H%M%S)"
        echo "✅ 已备份: $file"
    else
        echo "❌ 文件不存在: $file"
    fi
}

# 系统信息快览
sysinfo() {
    echo "════════════════════════════════════════"
    echo "🖥️  系统信息"
    echo "════════════════════════════════════════"
    echo "系统: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
    echo "内核: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "运行时间: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo "负载: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "💾 内存使用:"
    free -h 2>/dev/null | grep -E "Mem|Swap" || echo "内存信息不可用"
    echo ""
    echo "💿 磁盘使用:"
    df -h / 2>/dev/null | tail -1 || echo "磁盘信息不可用"
    echo ""
    if command -v docker &> /dev/null && systemctl is-active --quiet docker 2>/dev/null; then
        echo "🐳 Docker: 运行中 ($(docker ps -q 2>/dev/null | wc -l) 个容器)"
    fi
    if systemctl is-active --quiet mihomo 2>/dev/null; then
        echo "🌐 Clash: 运行中"
    fi
}

# Git 快速操作
gacp() {
    if [ $# -eq 0 ]; then
        echo "用法: gacp <提交信息>"
        return 1
    fi
    
    git add .
    git commit -m "$*"
    git push
}

# 快速服务器信息
myip() {
    echo "📍 IP 地址信息:"
    echo "  本地 IP: $(hostname -I | awk '{print $1}' 2>/dev/null || echo "未知")"
    
    if [ -n "$HTTP_PROXY" ]; then
        echo "  代理 IP: $(curl -x "$HTTP_PROXY" -s --connect-timeout 5 http://ifconfig.me 2>/dev/null || echo "获取失败")"
    fi
    
    echo "  公网 IP: $(curl -s --connect-timeout 5 http://ifconfig.me 2>/dev/null || echo "获取失败")"
}

# ============================================================================
# 自动补全和快捷键
# ============================================================================

# 历史搜索
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# 单词跳转
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ============================================================================
# 启动信息
# ============================================================================

# 显示欢迎信息
if [ -f "$HOME/.welcome" ]; then
    cat "$HOME/.welcome"
fi

# PowerLevel10k 即时提示
# 如果已配置 PowerLevel10k，启用即时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PowerLevel10k 配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh