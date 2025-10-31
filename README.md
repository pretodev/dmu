# DMU - Dart Multi-Repo Utility

A command-line tool to manage Git dependencies as local packages in Dart/Flutter projects.

## 🚀 Features

- **Local Development**: Clone Git dependencies locally for easier debugging and development
- **Automatic Override**: Automatically configure `dependency_overrides` in pubspec.yaml
- **Multi-Package Support**: Manage dependencies across multiple packages in your workspace
- **FVM Compatible**: Automatically detects and uses FVM if `.fvmrc` is present
- **Clean & Simple**: Intuitive commands with helpful error messages

## 📦 Installation

### Global Installation

```bash
dart pub global activate --source path .
```

Or add to your PATH:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Local Development

```bash
dart run bin/dmu.dart <command>
```

## 🎯 Usage

### Add a Package

Clone a Git dependency locally and set it up for local development:

```bash
dmu add <package-name> [--path <directory>]
```

**Options:**
- `--path`: Directory where package will be cloned (default: `packages`)

**Example:**
```bash
dmu add my_package
dmu add my_package --path libs
```

**What it does:**
1. Verifies package exists in dependencies as Git repo
2. Clones repository to specified path
3. Adds `dependency_override` to pubspec.yaml
4. Runs flutter clean && flutter pub get
5. Updates .gitignore to exclude packages directory

---

### Remove a Package

Remove local override and delete the cloned package:

```bash
dmu remove <package-name>
```

**Example:**
```bash
dmu remove my_package
```

**What it does:**
1. Verifies package is in dependency_overrides
2. Removes override from pubspec.yaml
3. Deletes local package directory
4. Runs flutter clean && flutter pub get

⚠️ **Warning:** Uncommitted changes in the local package will be lost!

---

### Download Dependencies

Run pub get on all Dart/Flutter packages in the project:

```bash
dmu pub-get
```

**Requirements:**
- `fd` command-line tool must be installed
  - macOS: `brew install fd`
  - Linux: `apt install fd-find`

**What it does:**
1. Searches for all pubspec.yaml files in the project
2. Runs flutter pub get (or dart pub get) on each package
3. Uses fvm flutter if .fvmrc file is detected

---

### Clean Build Artifacts

Clean build artifacts and caches from all packages:

```bash
dmu clean [--deep]
```

**Options:**
- `-d, --deep`: Also removes pubspec.lock files for complete dependency resolution reset

**Examples:**
```bash
dmu clean              # Standard clean
dmu clean --deep       # Deep clean with lock file removal
```

**What it does:**
- Standard clean: Runs flutter clean on all packages
- Deep clean: Also removes all pubspec.lock files

---

## 📋 Requirements

- Dart SDK 3.9.0 or higher
- Git (for cloning repositories)
- `fd` tool (for pub-get and clean commands)
  - Install on macOS: `brew install fd`
  - Install on Linux: `apt install fd-find`

## 🔧 How It Works

DMU simplifies the workflow of developing multiple interconnected Dart/Flutter packages:

1. **Normal Setup**: Your packages use Git URLs in dependencies
2. **Local Development**: Use `dmu add` to work on packages locally
3. **Override Management**: DMU manages dependency_overrides automatically
4. **Clean Integration**: Packages directory is automatically added to .gitignore

### Example pubspec.yaml

**Before:**
```yaml
dependencies:
  my_package:
    git:
      url: https://github.com/user/my_package.git
      ref: main
```

**After `dmu add my_package`:**
```yaml
dependencies:
  my_package:
    git:
      url: https://github.com/user/my_package.git
      ref: main

dependency_overrides:
  my_package:
    path: packages/my_package
```

## 🆘 Getting Help

For general help:
```bash
dmu --help
```

For command-specific help:
```bash
dmu <command> --help
```

Examples:
```bash
dmu add --help
dmu remove --help
dmu pub-get --help
dmu clean --help
```

## 📝 License

Copyright (c) 2025

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
