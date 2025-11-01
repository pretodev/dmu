# DMU - Dart Multi-Repo Utility

[![pub package](https://img.shields.io/pub/v/dmu.svg)](https://pub.dev/packages/dmu)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful command-line tool to streamline local development of Git dependencies in Dart and Flutter projects. DMU makes it easy to clone, manage, and override dependencies for debugging and feature development.

## 🚀 Features

- **🔧 Local Development**: Clone Git dependencies locally for easier debugging and development
- **⚡ Automatic Override**: Automatically configure `dependency_overrides` in pubspec.yaml
- **📦 Multi-Package Support**: Manage dependencies across multiple packages in your workspace
- **🎯 FVM Compatible**: Automatically detects and uses FVM if `.fvmrc` is present
- **✨ Clean & Simple**: Intuitive commands with helpful error messages
- **🔄 Workspace Management**: Run pub get on all packages in your project with a single command

## 📦 Installation

Install DMU globally using pub:

```bash
dart pub global activate dmu
```

Make sure to add the pub cache bin directory to your PATH:

```bash
# Add this to your ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Shell Completion (Optional)

DMU supports tab-completion for package names in both zsh and bash.

#### Quick Install (Recommended)

If you have the repository cloned:

```bash
cd /path/to/dmu/completions
./install-completions.sh
```

The script will automatically detect your shell and configure completions.

#### Manual Setup

<details>
<summary>Click to expand manual installation instructions</summary>

##### Zsh Setup

1. **Install the completion script:**

```bash
# Create completions directory if it doesn't exist
mkdir -p ~/.zsh/completions

# Copy the completion script
curl -o ~/.zsh/completions/_dmu https://raw.githubusercontent.com/pretodev/dmu/main/completions/_dmu

# Or if you have the repo cloned:
cp /path/to/dmu/completions/_dmu ~/.zsh/completions/
```

2. **Add completions directory to fpath in your ~/.zshrc:**

```bash
# Add this to your ~/.zshrc before compinit
fpath=(~/.zsh/completions $fpath)
```

3. **Reload your shell configuration:**

```bash
# Remove cached completions and reload
rm -f ~/.zcompdump
exec zsh
```

##### Bash Setup

1. **Install the completion script:**

```bash
# Download the completion script
curl -o ~/.dmu-completion.bash https://raw.githubusercontent.com/pretodev/dmu/main/completions/dmu-completion.bash

# Or if you have the repo cloned:
cp /path/to/dmu/completions/dmu-completion.bash ~/.dmu-completion.bash
```

2. **Add to your ~/.bashrc:**

```bash
# Add this to your ~/.bashrc
source ~/.dmu-completion.bash
```

3. **Reload your shell configuration:**

```bash
source ~/.bashrc
```

</details>

#### Using Tab-Completion

Now you can use tab-completion:
- `dmu add <TAB>` - Lists all Git dependencies that can be added
- `dmu remove <TAB>` - Lists all packages currently in dependency_overrides
- `dmu add my_pack<TAB>` - Auto-completes package names starting with "my_pack"

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

## 🌐 Supported Git Providers

DMU supports multiple Git hosting providers with automatic SSH URL conversion:

- **GitHub** - `https://github.com/owner/repo.git`
- **GitLab** - `https://gitlab.com/owner/repo.git` (including self-hosted)
- **Bitbucket** - `https://bitbucket.org/owner/repo.git`
- **Azure DevOps** - `https://dev.azure.com/org/project/_git/repo`
- **Gitea** - `https://gitea.example.com/owner/repo.git`
- **Generic Git** - Any standard Git hosting provider

### How It Works

When cloning repositories, DMU:
1. Attempts to clone using SSH (converted from HTTPS URL)
2. Falls back to HTTPS if SSH fails (e.g., no SSH keys configured)

This ensures maximum compatibility regardless of your Git configuration.

See [lib/src/git/README.md](lib/src/git/README.md) for detailed information about URL conversion and adding custom providers.

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

## � License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📚 Additional Resources

- [Documentation](https://pub.dev/documentation/dmu/latest/)
- [Report Issues](https://github.com/pretodev/dmu/issues)
- [Source Code](https://github.com/pretodev/dmu)

## 💡 Use Cases

### Multi-Package Workspace Development
Perfect for teams working on multiple interconnected packages where you need to test changes across packages before publishing.

### Package Development & Testing
Ideal for package authors who need to test their packages in real-world applications before releasing new versions.

### Debugging Dependencies
Makes it easy to dive into dependency source code, add debug prints, and understand issues without forking repositories.

