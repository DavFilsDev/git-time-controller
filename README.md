# Git Time Controller

A tool to modify the date of the last commit in Git repositories with automatic hook integration.

## Features
- Change date of the last commit
- Automatic pre-push hook installation
- Custom date format support
- Easy installation/uninstallation

## Project Structure

```
git-time-controller/
├── README.md
├── install.sh
├── uninstall.sh
├── LICENSE
├── src/
│   ├── git-date-modifier.sh
│   ├── git-hook.sh
│   └── setup-hooks.sh
├── examples/
│   ├── basic-usage.md
│   └── advanced-usage.md
└── tests/
    └── run-all-tests.sh
    ├── test-core-functionality.sh
    ├── test-environment.sh
    ├── test-error-handling.sh
    ├── test-hooks.sh
    ├── test-performance.sh
    ├── test-ui-output.sh
    └── test-utils.sh
```

## Installation

```bash
# Make install script executable
chmod +x install.sh

# Install globally
sudo ./install.sh
```

Or install locally in a specific repository:
```bash
./src/setup-hooks.sh
```

## Usage

### Change last commit date:
```bash
git-date-modifier --date "2024-01-15 14:30:00"
```

### With custom format:
```bash
git-date-modifier --date "Jan 15 2024 14:30" --format "%b %d %Y %H:%M"
```

### Available formats:
- ISO: "YYYY-MM-DD HH:MM:SS" (default)
- Relative: "2 days ago", "1 hour ago"
- RFC2822: "Mon, 15 Jan 2024 14:30:00 +0000"

## Requirements
- Git 2.0+
- Bash 4.0+
- Linux/Unix system

## License
MIT