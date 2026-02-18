# PIKA

> Apple Development Kit for remote iOS/macOS development with OpenClaw.

One-command setup to turn your Mac mini into a remote iOS development server. Control builds, tests, and screenshots from Telegram.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/zhaodengfeng/PIKA/main/install-ios-dev.sh | bash
```

## Features

- **One-command setup** - Installs Homebrew, Node.js, OpenClaw, and configures Xcode
- **Remote control** - Build, test, and screenshot via Telegram messages
- **Automation** - Schedule daily builds with cron
- **Safe** - Command whitelist restricts to build-related operations only

## Usage

### Telegram Commands

Send to your Bot:

```
执行：ios-build [project]     # Build project (default: MyFirstApp)
执行：ios-run [project]       # Build + run + screenshot
执行：ios-test [project]      # Run tests
执行：ios-screenshot          # Screenshot current simulator
执行：ios-clean [project]     # Clean build cache
执行：ios-list                # List all projects
```

### Local Aliases

```bash
ios-build MyApp    # Build
ios-run            # Build and run
ios-test           # Run tests
ios-screenshot     # Screenshot
ios-list           # List projects
```

## Requirements

- macOS 12+ (Monterey)
- Apple Silicon or Intel Mac
- 20GB+ disk space (Xcode + simulators)
- Free Apple ID

## Project Structure

```
PIKA/
├── install-ios-dev.sh      # One-time setup script
├── ios-dev-automation.sh   # Daily automation tasks
└── README.md
```

## Configuration

Environment variables (optional):

```bash
export PROJECTS_DIR="$HOME/Projects"
export DEFAULT_SIMULATOR="iPhone 16"
```

## License

[GPL-3.0](LICENSE)

## Acknowledgments

- [OpenClaw](https://github.com/openclaw/openclaw) - Remote agent platform
- [Homebrew](https://brew.sh) - macOS package manager
