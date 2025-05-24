# AliasX - Enhanced Bash Aliases with Parameters

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Creating Aliases](#creating-aliases)
  - [Using Placeholders](#using-placeholders)
  - [Managing Aliases](#managing-aliases)
- [Examples](#examples)
- [Uninstallation](#uninstallation)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Introduction

AliasX supercharges your terminal experience by allowing you to create powerful parameterized aliases in Bash/Zsh. Unlike traditional aliases, AliasX supports:

- Positional parameters (`{1}`, `{2}`, etc.)
- All arguments placeholder (`{*}`)
- Easy alias management
- Command preview before execution

## Features

✨ **Parameterized Aliases** - Create aliases that accept arguments  
📝 **Command Preview** - See exactly what will execute before running  
📂 **Persistent Storage** - Aliases survive terminal sessions  
🔍 **Easy Management** - List, edit, and remove aliases with simple commands  
🔄 **Auto-reload** - Changes take effect immediately  
🎨 **Colorized Output** - Easy-to-read colored terminal output  
🔧 **Cross-shell** - Works in both Bash and Zsh  

## Installation

### One-line Install (recommended)
```bash
bash <(curl -sSL https://raw.githubusercontent.com/wqttzicue/AliasX/stable/aliasx-installer.sh) --install && exec bash
```

### Manual Install
1. Download the installer:
```bash
curl -sSL https://raw.githubusercontent.com/wqttzicue/AliasX/stable/aliasx-installer.sh -o aliasx-installer.sh
```
2. Run the installer:
```bash
bash aliasx-installer.sh --install
```

After installation, restart your terminal or run:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

## Usage

### Creating Aliases
```bash
aliasx <name> "<command>"
```

### Using Placeholders
| Placeholder | Description                     | Example                     |
|-------------|---------------------------------|-----------------------------|
| `{1}`-`{9}` | Positional arguments            | `aliasx mk "mkdir -p {1}"`  |
| `{*}`       | All arguments as single string  | `aliasx echoall "echo {*}"` |

### Managing Aliases
| Command               | Description                          | Example                  |
|-----------------------|--------------------------------------|--------------------------|
| `aliasx -L`           | List all aliases                     | `aliasx -L`              |
| `aliasx -R <name>`    | Remove an alias                      | `aliasx -R myalias`      |
| `aliasx -H`           | Show help                            | `aliasx -H`              |
| `aliasx -V`           | Show version                         | `aliasx -V`              |
| `aliasx -U`           | Uninstall AliasX                     | `aliasx -U`              |

## Examples

### File Operations
```bash
# Create directory and immediately cd into it
aliasx mkcd "mkdir -p {1} && cd {1}"

# Search in files with highlight
aliasx search "grep -rn --color=auto {1} {2}"

# Count files in directory
aliasx count "ls {1} | wc -l"
```

### Git Shortcuts
```bash
# Git commit with message
aliasx gcm "git commit -m \"{*}\""

# Git log with pretty format
aliasx glog "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit {*}"

# Git status short
aliasx gst "git status -sb {*}"
```

### System Monitoring
```bash
# Find process by name
aliasx findp "ps aux | grep -v grep | grep {1}"

# Show disk usage sorted
aliasx dusage "du -h {1} | sort -h"
```

### Network Tools
```bash
# Quick ping with count
aliasx qping "ping -c 4 {1}"

# Test SSL certificate
aliasx sslcheck "openssl s_client -connect {1}:{2} -servername {1} 2>/dev/null | openssl x509 -noout -dates"
```

## Uninstallation

### Method 1: Using AliasX
```bash
aliasx -U
```

### Method 2: Direct Uninstall
```bash
bash <(curl -sSL https://raw.githubusercontent.com/wqttzicue/AliasX/stable/aliasx-installer.sh) --uninstall
```

This will remove:
- All AliasX configuration files
- Shell integrations
- Created aliases
- Backup files

## FAQ

**Q: How is this different from regular shell aliases?**  
A: Regular aliases don't support parameters. AliasX lets you create dynamic aliases with placeholders.

**Q: Where are the aliases stored?**  
A: In `~/.aliasx_aliases`. You can edit this file directly if needed.

**Q: Can I use this in scripts?**  
A: Yes! AliasX aliases work just like regular commands.

**Q: Can I use environment variables in aliases?**  
A: Yes, variables will expand when the alias runs, not when it's created.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

Report issues in the GitHub issue tracker.
