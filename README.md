# ADS - Apple Dev Setup

> Apple Development Setup Script - 苹果开发环境一键配置脚本

配合 **OpenClaw** 实现远程 iOS/macOS 开发，让你在手机上就能控制 Mac 构建、测试、截图。

---

## 🚀 快速开始

在 Mac mini 终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/zhaodengfeng/apple-dev-setup/main/install-ios-dev.sh | bash
```

安装完成后，在 Telegram 发送消息即可远程控制：

```
执行：ios-build    # 构建项目
执行：ios-run      # 构建+运行+截图
执行：ios-test     # 运行测试
```

---

## 📋 功能特性

| 功能 | 说明 |
|------|------|
| ✅ 自动安装 | Homebrew、Node.js、OpenClaw、Xcode 检查 |
| 📱 远程控制 | Telegram 消息控制 Mac 开发 |
| 🔨 自动构建 | `xcodebuild` 构建 iOS/macOS 项目 |
| 🧪 运行测试 | XCTest 自动化测试 |
| 📸 自动截图 | 模拟器/真机截图并发送 |
| ⏰ 定时任务 | 每日自动构建检查 |
| 🧹 一键清理 | 清理 Xcode 缓存 |

---

## 📁 文件说明

```
apple-dev-setup/
├── install-ios-dev.sh      # 一键安装脚本（首次运行）
├── ios-dev-automation.sh   # 自动化任务脚本（日常使用）
└── README.md               # 本文件
```

---

## 💬 Telegram 命令

安装后，发送给 Bot：

| 命令 | 功能 |
|------|------|
| `执行：ios-build [项目名]` | 构建项目（默认 MyFirstApp） |
| `执行：ios-run [项目名]` | 构建 + 运行 + 截图 |
| `执行：ios-test [项目名]` | 运行单元测试 |
| `执行：ios-screenshot` | 当前模拟器截图 |
| `执行：ios-clean [项目名]` | 清理构建缓存 |
| `执行：ios-list` | 列出所有项目 |
| `执行：ios-analyze` | 分析上次构建日志 |

---

## 🔧 本地快捷命令

在 Mac 终端使用：

```bash
ios-build MyFirstApp    # 构建
ios-run                 # 构建并运行
ios-test                # 运行测试
ios-screenshot          # 截图
ios-clean               # 清理
ios-list                # 列出项目
ios-analyze             # 分析日志
```

---

## ⚙️ 配置说明

### 环境变量

```bash
export PROJECTS_DIR="$HOME/Projects"    # 项目根目录
export DEFAULT_SIMULATOR="iPhone 16"     # 默认模拟器
```

### OpenClaw 配置

安装脚本会自动配置 `~/.openclaw/openclaw.json`：

- Telegram 频道
- 命令白名单（xcodebuild、xcrun 等）
- 定时构建任务

---

## 📸 使用场景

### 场景 1：iPad 写代码，Mac 自动构建

1. iPad 上用 Swift Playgrounds 或 Git 客户端改代码
2. 同步到 Mac mini
3. Telegram 发送 `执行：ios-build`
4. 收到构建结果 + 截图

### 场景 2：自动化测试

```bash
# 每天早上 9 点自动构建
openclaw cron add \
  --name "daily-build" \
  --schedule "0 9 * * *" \
  --command "ios-build"
```

### 场景 3：多台设备测试

```bash
# 构建后在 iPhone 15 截图
ios-run MyApp
# 切换模拟器再截图
ios-screenshot
```

---

## 🛠️ 系统要求

- macOS 12+ (Monterey 或更新)
- Apple Silicon Mac (M1/M2/M3/M4) 或 Intel Mac
- 至少 20GB 磁盘空间（Xcode + 模拟器）
- Apple ID（免费账号即可）

---

## 📝 手动安装步骤

如果不想一键安装，可以手动：

```bash
# 1. 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安装 Node.js
brew install node

# 3. 安装 OpenClaw
npm install -g openclaw@latest

# 4. 安装 Xcode（App Store 或命令行）
xcode-select --install
sudo xcodebuild -license accept

# 5. 配置 Telegram Bot
# 编辑 ~/.openclaw/openclaw.json

# 6. 复制脚本
cp ios-dev-automation.sh ~/.openclaw/workspace/
chmod +x ~/.openclaw/workspace/ios-dev-automation.sh
```

---

## 🔒 安全说明

- Token 存储在本地 `~/.openclaw/openclaw.json`
- 命令白名单限制只能执行构建相关命令
- 建议开启 Telegram 两步验证

---

## 🐛 故障排除

| 问题 | 解决 |
|------|------|
| `xcodebuild: command not found` | 安装 Xcode 并执行 `xcode-select --install` |
| `未找到 .xcodeproj` | 确认项目名正确，且目录下有 .xcodeproj 文件 |
| 截图失败 | 确保模拟器已启动，先用 `ios-run` |
| 构建失败 | 用 `ios-analyze` 查看详细日志 |

---

## 📄 License

MIT License - 自由使用、修改、分发

---

## 🙏 致谢

- [OpenClaw](https://github.com/openclaw/openclaw) - 让远程开发成为可能
- [Homebrew](https://brew.sh) - macOS 包管理器
- [Xcode](https://developer.apple.com/xcode/) - Apple 官方开发工具

---

**Made with ❤️ by Z.D.F**
