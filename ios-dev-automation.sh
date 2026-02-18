#!/bin/bash
# iOS 开发自动化脚本 - 由 OpenClaw 管理
# 用法: ./ios-dev-automation.sh [命令] [项目名]

set -e

# 配置
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"
LOG_DIR="$HOME/.openclaw/ios-logs"
mkdir -p "$LOG_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"
}

# 获取项目路径
get_project_path() {
    local project_name="${1:-MyFirstApp}"
    echo "$PROJECTS_DIR/$project_name"
}

# 获取 .xcodeproj 文件名
get_xcodeproj() {
    local project_path="$1"
    local proj=$(find "$project_path" -maxdepth 1 -name "*.xcodeproj" | head -1)
    if [ -z "$proj" ]; then
        error "未找到 .xcodeproj 文件"
        exit 1
    fi
    basename "$proj"
}

# 获取 scheme 名称
get_scheme() {
    local project_path="$1"
    local proj_name=$(get_xcodeproj "$project_path")
    # 去掉 .xcodeproj 后缀
    echo "${proj_name%.xcodeproj}"
}

# 命令：构建
cmd_build() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local xcodeproj=$(get_xcodeproj "$project_path")
    local scheme=$(get_scheme "$project_path")
    local log_file="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
    
    log "开始构建项目: $project_name"
    log "项目路径: $project_path"
    log "Scheme: $scheme"
    log "日志文件: $log_file"
    
    cd "$project_path"
    
    # 执行构建
    if xcodebuild -project "$xcodeproj" \
                  -scheme "$scheme" \
                  -destination "platform=iOS Simulator,name=iPhone 16" \
                  build > "$log_file" 2>&1; then
        log "✅ 构建成功！"
        
        # 获取构建产物路径
        local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "*.app" -path "*/Build/Products/*" -newer "$log_file" 2>/dev/null | head -1)
        if [ -n "$app_path" ]; then
            log "📦 App 路径: $app_path"
        fi
        
        return 0
    else
        error "❌ 构建失败"
        log "最后 30 行日志:"
        tail -30 "$log_file"
        return 1
    fi
}

# 命令：测试
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

# 命令：截图
cmd_screenshot() {
    local project_name="${1:-MyFirstApp}"
    local screenshot_path="$PROJECTS_DIR/$project_name/screenshot-$(date +%H%M%S).png"
    
    log "📸 正在截图..."
    
    # 确保模拟器已启动
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

# 命令：运行（构建+启动+截图）
cmd_run() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local scheme=$(get_scheme "$project_path")
    
    log "🚀 开始完整运行流程..."
    
    # 构建
    cmd_build "$project_name" || return 1
    
    # 启动模拟器
    log "启动模拟器..."
    xcrun simctl boot "iPhone 16" 2>/dev/null || log "模拟器已在运行"
    
    # 安装并启动 App
    log "安装 App..."
    local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "${scheme}.app" -path "*/Build/Products/Debug-iphonesimulator/*" 2>/dev/null | head -1)
    
    if [ -n "$app_path" ]; then
        xcrun simctl install booted "$app_path"
        log "启动 App..."
        xcrun simctl launch booted "$(basename "$app_path" .app)"
        sleep 3
        
        # 截图
        cmd_screenshot "$project_name"
    else
        warn "未找到 App 文件，跳过安装"
    fi
}

# 命令：清理
cmd_clean() {
    local project_name="${1:-MyFirstApp}"
    local project_path=$(get_project_path "$project_name")
    local xcodeproj=$(get_xcodeproj "$project_path")
    
    log "🧹 清理项目..."
    cd "$project_path"
    xcodebuild -project "$xcodeproj" clean
    log "✅ 清理完成"
}

# 命令：分析日志
cmd_analyze() {
    local log_file="$1"
    if [ -z "$log_file" ]; then
        # 找最新的日志
        log_file=$(ls -t "$LOG_DIR"/build-*.log 2>/dev/null | head -1)
    fi
    
    if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
        error "未找到日志文件"
        return 1
    fi
    
    log "分析日志: $log_file"
    
    # 提取错误信息
    local errors=$(grep -E "(error:|Error|ERROR|❌)" "$log_file" | head -10)
    if [ -n "$errors" ]; then
        error "发现的错误:"
        echo "$errors"
    else
        log "未找到明显错误"
    fi
    
    # 提取警告
    local warnings=$(grep -E "(warning:|Warning|WARNING)" "$log_file" | wc -l)
    log "警告数量: $warnings"
    
    # 构建时间
    local build_time=$(grep -E "Build complete|BUILD SUCCEEDED|BUILD FAILED" "$log_file")
    if [ -n "$build_time" ]; then
        log "构建结果: $build_time"
    fi
}

# 命令：列出项目
cmd_list() {
    log "📁 项目列表 ($PROJECTS_DIR):"
    if [ -d "$PROJECTS_DIR" ]; then
        for dir in "$PROJECTS_DIR"/*/; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                if [ -d "$dir"/*.xcodeproj 2>/dev/null ]; then
                    echo "  ✅ $name (Xcode 项目)"
                else
                    echo "  📁 $name"
                fi
            fi
        done
    else
        warn "项目目录不存在: $PROJECTS_DIR"
    fi
}

# 命令：帮助
cmd_help() {
    cat << 'EOF'
iOS 开发自动化脚本

用法: ./ios-dev-automation.sh <命令> [项目名]

命令:
  build [项目名]      构建项目
  test [项目名]       运行测试
  run [项目名]        构建+运行+截图
  screenshot [项目名]  截图当前模拟器
  clean [项目名]      清理构建缓存
  analyze [日志文件]   分析构建日志
  list                列出所有项目
  help                显示帮助

示例:
  ./ios-dev-automation.sh build MyFirstApp
  ./ios-dev-automation.sh run
  ./ios-dev-automation.sh test MyApp

环境变量:
  PROJECTS_DIR        项目根目录 (默认: ~/Projects)
EOF
}

# 主入口
case "${1:-help}" in
    build)
        cmd_build "$2"
        ;;
    test)
        cmd_test "$2"
        ;;
    run)
        cmd_run "$2"
        ;;
    screenshot)
        cmd_screenshot "$2"
        ;;
    clean)
        cmd_clean "$2"
        ;;
    analyze)
        cmd_analyze "$2"
        ;;
    list)
        cmd_list
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        error "未知命令: $1"
        cmd_help
        exit 1
        ;;
esac
