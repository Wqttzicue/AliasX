# AliasX - Enhanced Bash Aliases with Parameters

[![License](https://img.shields.io/badge/license-GNU-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)]()

AliasX supercharges your Bash aliases by adding parameter support, making them as powerful as functions while keeping them simple to manage.

## ✨ Features

- **Parameterized aliases** using `{1}`, `{2}` placeholders
- **Persistent storage** of aliases between sessions
- **Simple management**:
  - Add/update aliases with `aliasx <name> <command>`
  - Remove aliases with `aliasx -R <name>`
  - List aliases with `aliasx -L`
- **Automatic loading** in new terminal sessions
- **Lightweight** - No dependencies, pure Bash
- **Placeholder support**:
  - `{1}`–`{9}` for positional arguments
  - `{*}` for all arguments

## 🚀 Installation

### Recommended Method

```bash
curl -s https://raw.githubusercontent.com/Wqttzicue/AliasX/stable/aliasx-installer.sh -o aliasx-installer.sh
bash aliasx-installer.sh
exec bash
```

## ⚠️ Removal

### Recommended Method
```bash
rm -f ~/.aliasx_loader ~/.aliasx_aliases && sed -i '/# AliasX Configuration/,+1d' ~/.bashrc && { [ -f ~/.aliasx_aliases ] && while IFS='|' read -r name _; do unset -f "$name" 2>/dev/null; done < ~/.aliasx_aliases; unset -f aliasx load_aliases 2>/dev/null; } && echo "AliasX has been completely removed"
