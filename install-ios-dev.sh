#!/bin/bash
# OpenClaw iOS 开发环境一键安装脚本
# 适用于 Mac mini (macOS)
# 用法: curl -fsSL https://你的地址/install-ios-dev.sh | bash
# 或保存后执行: ./install-ios-dev.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# 获取用户输入
read_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        read -p "$prompt: " input
    fi
    echo "$input"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# 1. 安装 Homebrew
install_homebrew() {
    info "检查 Homebrew..."
    if command_exists brew; then
        log "Homebrew 已安装: $(brew --version | head -1)"
        return 0
    fi
    
    warn "Homebrew 未安装，开始安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # 添加到 PATH
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    log "Homebrew 安装完成"
}

# 2. 安装 Node.js
install_node() {
    info "检查 Node.js..."
    if command_exists node; then
        local version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$version" -ge 22 ]; then
            log "Node.js 已安装: $(node -v)"
            return 0
        else
            warn "Node.js 版本过低 ($(node -v))，需要 22+"
        fi
    fi
    
    warn "安装 Node.js 22..."
    brew install node
    log "Node.js 安装完成: $(node -v)"
}

# 3. 安装 OpenClaw
install_openclaw() {
    info "检查 OpenClaw..."
    if command_exists openclaw; then
        log "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo 'unknown')"
        return 0
    fi
    
    warn "安装 OpenClaw..."
    
    # 方法1: 官方安装脚本
    if curl -fsSL https://openclaw.ai/install.sh | bash; then
        log "OpenClaw 安装完成"
    else
        # 方法2: npm 安装
        warn "脚本安装失败，尝试 npm 安装..."
        npm install -g openclaw@latest
        log "OpenClaw 安装完成 (npm)"
    fi
    
    # 确保在 PATH 中
    export PATH="$(npm prefix -g)/bin:$PATH"
}

# 4. 检查 Xcode
check_xcode() {
    info "检查 Xcode..."
    if command_exists xcodebuild; then
        log "Xcode 已安装: $(xcodebuild -version | head -1)"
        
        # 检查许可协议
        if ! xcodebuild -license check &>/dev/null; then
            warn "需要接受 Xcode 许可协议"
            info "请在弹出的对话框中点击同意，或在终端运行: sudo xcodebuild -license accept"
        fi
        return 0
    fi
    
    warn "Xcode 未安装"
    echo ""
    echo "请通过以下方式之一安装 Xcode:"
    echo "  1. App Store 搜索 'Xcode' 安装 (~10GB，需要 Apple ID)"
    echo "  2. 访问 https://developer.apple.com/download/all/ 下载"
    echo ""
    echo "安装完成后，重新运行此脚本。"
    exit 1
}

# 5. 创建自动化脚本
create_automation_script() {
    info "创建 iOS 自动化脚本..."
    
    local script_dir="$HOME/.openclaw/workspace"
    local script_path="$script_dir/ios-dev-automation.sh"
    
    mkdir -p "$script_dir"
    
    cat > "$script_path" << 'SCRIPT_EOF'
#!/bin/bash
# iOS 开发自动化脚本 - 由 OpenClaw 管理
set -e

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
LOG_DIR="$HOME/.openclaw/ios-logs"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

get_project_path() {
    local project_name="${1:-MyFirstApp}"
    echo "$PROJECTS_DIR/$project_name"
}

get_xcodeproj() {
    local project_path="$1"
    local proj=$(find "$project_path" -maxdepth 1 -name "*.xcodeproj" | head -1)
    if [ -z "$proj" ]; then
        error "未找到 .xcodeproj 文件"
        exit 1
    fi
    basename "$proj"
}

get_scheme() {
    local project_path="$1"
    local proj_name=$(get_xcodeproj "$project_path")
    echo "${proj_name%.xcodeproj}"
}

cmd_build() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local xcodeproj=$(get_xcodeproj "$project_path")
    local scheme=$(get_scheme "$project_path")
    local log_file="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
    
    log "开始构建项目: $project_name"
    log "项目路径: $project_path"
    log "Scheme: $scheme"
    
    cd "$project_path"
    
    if xcodebuild -project "$xcodeproj" \
                  -scheme "$scheme" \
                  -destination "platform=iOS Simulator,name=iPhone 16" \
                  build > "$log_file" 2>&1; then
        log "✅ 构建成功！"
        local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "*.app" -path "*/Build/Products/*" -newer "$log_file" 2>/dev/null | head -1)
        [ -n "$app_path" ] && log "📦 App 路径: $app_path"
        return 0
    else
        error "❌ 构建失败"
        log "最后 30 行日志:"
        tail -30 "$log_file"
        return 1
    fi
}

cmd_test() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local xcodeproj=$(get_xcodeproj "$project_path")
    local scheme=$(get_scheme "$project_path")
    local log_file="$LOG_DIR/test-$(date +%Y%m%d-%H%M%S).log"
    
    log "开始测试项目: $project_name"
    cd "$project_path"
    
    if xcodebuild -project "$xcodeproj" \
                  -scheme "$scheme" \
                  -destination "platform=iOS Simulator,name=iPhone 16" \
                  test > "$log_file" 2>&1; then
        log "✅ 测试通过！"
        grep -E "(Test Suite|Executed|passed|failed)" "$log_file" | tail -5
        return 0
    else
        error "❌ 测试失败"
        tail -50 "$log_file"
        return 1
    fi
}

cmd_screenshot() {
    local project_name="${1:-}"
    local screenshot_name="screenshot-$(date +%H%M%S).png"
    local screenshot_path
    
    if [ -n "$project_name" ]; then
        screenshot_path="$PROJECTS_DIR/$project_name/$screenshot_name"
    else
        screenshot_path="$LOG_DIR/$screenshot_name"
    fi
    
    log "📸 正在截图..."
    xcrun simctl boot "iPhone 16" 2>/dev/null || true
    sleep 2
    
    if xcrun simctl io booted screenshot "$screenshot_path"; then
        log "✅ 截图保存: $screenshot_path"
        echo "$screenshot_path"
        return 0
    else
        error "❌ 截图失败"
        return 1
    fi
}

cmd_run() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local scheme=$(get_scheme "$project_path")
    
    log "🚀 开始完整运行流程..."
    cmd_build "$project_name" || return 1
    
    log "启动模拟器..."
    xcrun simctl boot "iPhone 16" 2>/dev/null || log "模拟器已在运行"
    
    log "安装 App..."
    local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "${scheme}.app" -path "*/Build/Products/Debug-iphonesimulator/*" 2>/dev/null | head -1)
    
    if [ -n "$app_path" ]; then
        xcrun simctl install booted "$app_path"
        log "启动 App..."
        xcrun simctl launch booted "$(basename "$app_path" .app)"
        sleep 3
        cmd_screenshot "$project_name"
    else
        warn "未找到 App 文件"
    fi
}

cmd_clean() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local xcodeproj=$(get_xcodeproj "$project_path")
    
    log "🧹 清理项目..."
    cd "$project_path"
    xcodebuild -project "$xcodeproj" clean
    log "✅ 清理完成"
}

cmd_analyze() {
    local log_file="$1"
    if [ -z "$log_file" ]; then
        log_file=$(ls -t "$LOG_DIR"/build-*.log 2>/dev/null | head -1)
    fi
    
    if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
        error "未找到日志文件"
        return 1
    fi
    
    log "分析日志: $log_file"
    local errors=$(grep -E "(error:|Error|ERROR|❌)" "$log_file" | head -10)
    if [ -n "$errors" ]; then
        error "发现的错误:"
        echo "$errors"
    else
        log "未找到明显错误"
    fi
    
    local warnings=$(grep -E "(warning:|Warning|WARNING)" "$log_file" | wc -l)
    log "警告数量: $warnings"
}

cmd_list() {
    log "📁 项目列表 ($PROJECTS_DIR):"
    if [ -d "$PROJECTS_DIR" ]; then
        for dir in "$PROJECTS_DIR"/*/; do
            [ -d "$dir" ] || continue
            local name=$(basename "$dir")
            if ls "$dir"/*.xcodeproj >/dev/null 2>&1; then
                echo "  ✅ $name"
            else
                echo "  📁 $name (非 Xcode 项目)"
            fi
        done
    else
        warn "项目目录不存在: $PROJECTS_DIR"
    fi
}

cmd_help() {
    cat << 'EOF'
iOS 开发自动化脚本

用法: ios-dev [命令] [项目名]

命令:
  build [项目名]      构建项目 (默认: MyFirstApp)
  test [项目名]       运行测试
  run [项目名]        构建+运行+截图
  screenshot [项目名]  截图当前模拟器
  clean [项目名]      清理构建缓存
  analyze [日志文件]   分析构建日志
  list                列出所有项目
  help                显示帮助

示例:
  ios-build                    # 构建 MyFirstApp
  ios-build MyFirstApp         # 构建指定项目
  ios-run                      # 构建并运行
  ios-test                     # 运行测试

快捷命令:
  ios-build = ios-dev build
  ios-run   = ios-dev run
  ios-test  = ios-dev test
EOF
}

case "${1:-help}" in
    build) cmd_build "$2" ;;
    test) cmd_test "$2" ;;
    run) cmd_run "$2" ;;
    screenshot) cmd_screenshot "$2" ;;
    clean) cmd_clean "$2" ;;
    analyze) cmd_analyze "$2" ;;
    list) cmd_list ;;
    help|--help|-h) cmd_help ;;
    *) error "未知命令: $1"; cmd_help; exit 1 ;;
esac
SCRIPT_EOF

    chmod +x "$script_path"
    log "自动化脚本创建完成: $script_path"
}

# 6. 创建快捷命令
create_aliases() {
    info "创建快捷命令..."
    
    local shell_rc="$HOME/.zshrc"
    [ "$SHELL" = "/bin/bash" ] && shell_rc="$HOME/.bashrc"
    
    local script_path="$HOME/.openclaw/workspace/ios-dev-automation.sh"
    
    # 检查是否已添加
    if grep -q "ios-dev-automation.sh" "$shell_rc" 2>/dev/null; then
        warn "快捷命令已存在，跳过"
        return 0
    fi
    
    cat >> "$shell_rc" << EOF

# OpenClaw iOS 开发快捷命令
alias ios-dev="$script_path"
alias ios-build="$script_path build"
alias ios-run="$script_path run"
alias ios-test="$script_path test"
alias ios-screenshot="$script_path screenshot"
alias ios-clean="$script_path clean"
alias ios-list="$script_path list"
EOF

    log "快捷命令已添加到 $shell_rc"
    log "运行 'source $shell_rc' 或重新打开终端以生效"
}

# 7. 配置 OpenClaw
configure_openclaw() {
    info "配置 OpenClaw..."
    
    local config_file="$HOME/.openclaw/openclaw.json"
    
    # 如果配置已存在，询问是否覆盖
    if [ -f "$config_file" ]; then
        warn "OpenClaw 配置已存在"
        local backup="$config_file.backup.$(date +%Y%m%d%H%M%S)"
        cp "$config_file" "$backup"
        log "原配置已备份: $backup"
    fi
    
    echo ""
    info "请配置 Telegram Bot"
    echo "1. 在 Telegram 搜索 @BotFather"
    echo "2. 发送 /newbot 创建新 Bot"
    echo "3. 复制获得的 Token"
    echo ""
    
    local bot_token=$(read_input "输入 Bot Token")
    local user_id=$(read_input "输入你的 Telegram User ID" "97775718")
    
    # 创建目录
    mkdir -p "$HOME/.openclaw"
    
    cat > "$config_file" << EOF
{
  "channels": {
    "telegram": {
      "botToken": "$bot_token",
      "dmPolicy": "allowlist",
      "allowFrom": ["$user_id"]
    }
  },
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "on-miss",
      "allowlist": [
        { "pattern": "/usr/bin/xcrun" },
        { "pattern": "/usr/bin/xcodebuild" },
        { "pattern": "/bin/bash" },
        { "pattern": "/bin/sh" },
        { "pattern": "/opt/homebrew/bin/*" },
        { "pattern": "/usr/local/bin/*" },
        { "pattern": "$HOME/.openclaw/workspace/ios-dev-automation.sh" },
        { "pattern": "$HOME/Projects/*" }
      ]
    }
  }
}
EOF

    log "OpenClaw 配置完成: $config_file"
}

# 8. 启动 OpenClaw
start_openclaw() {
    info "启动 OpenClaw Gateway..."
    
    if ! command_exists openclaw; then
        error "OpenClaw 命令未找到"
        return 1
    fi
    
    # 检查状态
    if openclaw status &>/dev/null; then
        log "OpenClaw 已在运行，重启以应用新配置..."
        openclaw gateway restart
    else
        log "启动 OpenClaw..."
        openclaw gateway start || openclaw onboard --install-daemon
    fi
    
    log "OpenClaw 已启动"
}

# 9. 创建示例项目
create_sample_project() {
    info "创建示例 iOS 项目..."
    
    local projects_dir="$HOME/Projects"
    local project_name="MyFirstApp"
    local project_path="$projects_dir/$project_name"
    
    if [ -d "$project_path" ]; then
        warn "项目 $project_name 已存在，跳过"
        return 0
    fi
    
    mkdir -p "$projects_dir"
    
    # 使用命令行创建最简单的 iOS 项目
    # 注意：这需要 Xcode 和完整的项目模板，这里只创建目录结构
    mkdir -p "$project_path"
    
    log "示例项目目录已创建: $project_path"
    warn "请使用 Xcode 创建实际项目:"
    warn "  打开 Xcode → Create New Project → iOS App"
    warn "  保存到: $project_path"
}

# 10. 设置定时任务
setup_cron() {
    info "设置定时构建任务..."
    
    local script_path="$HOME/.openclaw/workspace/ios-dev-automation.sh"
    
    echo ""
    echo "是否设置每日自动构建?"
    echo "  1) 每天早上 9 点"
    echo "  2) 每 4 小时检查一次"
    echo "  3) 不设置"
    echo ""
    
    local choice=$(read_input "选择" "1")
    
    case "$choice" in
        1)
            openclaw cron add \
                --name "daily-ios-build" \
                --schedule "0 9 * * *" \
                --command "$script_path build" 2>/dev/null || \
            warn "请手动添加定时任务: openclaw cron add --name daily-ios-build --schedule '0 9 * * *' --command '$script_path build'"
            log "已设置每天早上 9 点自动构建"
            ;;
        2)
            openclaw cron add \
                --name "quarterly-ios-check" \
                --schedule "0 */4 * * *" \
                --command "$script_path build" 2>/dev/null || \
            warn "请手动添加定时任务: openclaw cron add --name quarterly-ios-check --schedule '0 */4 * * *' --command '$script_path build'"
            log "已设置每 4 小时自动构建"
            ;;
        *)
            log "跳过定时任务设置"
            ;;
    esac
}

# 主函数
main() {
    echo "========================================"
    echo "  OpenClaw iOS 开发环境一键安装"
    echo "========================================"
    echo ""
    
    # 检查系统
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "此脚本仅适用于 macOS"
        exit 1
    fi
    
    # 执行安装步骤
    install_homebrew
    install_node
    install_openclaw
    check_xcode
    create_automation_script
    create_aliases
    configure_openclaw
    start_openclaw
    create_sample_project
    setup_cron
    
    echo ""
    echo "========================================"
    log "安装完成！"
    echo "========================================"
    echo ""
    echo "📱 使用 Telegram 控制你的 iOS 开发:"
    echo ""
    echo "   构建项目:"
    echo "     执行：ios-build"
    echo "     执行：ios-build MyFirstApp"
    echo ""
    echo "   构建并运行:"
    echo "     执行：ios-run"
    echo ""
    echo "   运行测试:"
    echo "     执行：ios-test"
    echo ""
    echo "   截图:"
    echo "     执行：ios-screenshot"
    echo ""
    echo "   列出项目:"
    echo "     执行：ios-list"
    echo ""
    echo "📋 下一步:"
    echo "   1. 打开 Xcode，创建你的第一个 iOS App"
    echo "      保存到: ~/Projects/MyFirstApp"
    echo "   2. 在 Telegram 中给你的 Bot 发送消息测试"
    echo "   3. 运行 'source ~/.zshrc' 使快捷命令生效"
    echo ""
}

# 运行
main "$@"
