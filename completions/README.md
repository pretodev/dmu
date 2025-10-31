# DMU Shell Completions

This directory contains shell completion scripts for DMU (Dart Multi-Repo Utility).

## Available Completions

- **`_dmu`**: Zsh completion script
- **`dmu-completion.bash`**: Bash completion script
- **`install-completions.sh`**: Automated installer for both shells

## Features

The completion scripts provide intelligent tab-completion for:

- **Commands**: `add`, `remove`, `pub-get`, `clean`, `completions`
- **Package names for `add`**: Auto-completes from Git dependencies in pubspec.yaml that haven't been added yet
- **Package names for `remove`**: Auto-completes from packages currently in dependency_overrides
- **Flags and options**: All command-specific flags like `--path`, `--deep`, `--help`
- **Partial matching**: Type part of a package name and press TAB to complete

## Quick Installation

### Automatic (Recommended)

```bash
./install-completions.sh
```

The script will detect your shell and install the appropriate completions automatically.

### Manual Installation

#### Zsh

1. Copy `_dmu` to a directory in your `fpath`:
   ```bash
   mkdir -p ~/.zsh/completions
   cp _dmu ~/.zsh/completions/
   ```

2. Add to your `~/.zshrc` (before `compinit`):
   ```bash
   fpath=(~/.zsh/completions $fpath)
   ```

3. Reload:
   ```bash
   rm -f ~/.zcompdump
   exec zsh
   ```

#### Bash

1. Copy the completion script:
   ```bash
   cp dmu-completion.bash ~/.dmu-completion.bash
   ```

2. Add to your `~/.bashrc`:
   ```bash
   source ~/.dmu-completion.bash
   ```

3. Reload:
   ```bash
   source ~/.bashrc
   ```

## How It Works

### For `dmu add`

The completion script runs `dmu completions` which returns a list of all Git dependencies from your `pubspec.yaml` that are NOT yet in `dependency_overrides`. This means you only see packages that can actually be added.

Example:
```bash
$ dmu add <TAB>
my_package        another_package        utils_package
```

### For `dmu remove`

The completion script reads your `pubspec.yaml` and extracts all package names from the `dependency_overrides` section. This ensures you only see packages that are currently overridden and can be removed.

Example:
```bash
$ dmu remove <TAB>
my_package        another_package
```

## Requirements

- DMU must be installed and available in PATH
- For `dmu add` completion: A valid `pubspec.yaml` with Git dependencies
- For `dmu remove` completion: A `pubspec.yaml` with `dependency_overrides`

## Troubleshooting

### Completions not working

1. **Verify DMU is in PATH**:
   ```bash
   which dmu
   ```

2. **Test the completions command**:
   ```bash
   dmu completions
   ```
   This should output a list of package names.

3. **For Zsh**: Clear completion cache
   ```bash
   rm -f ~/.zcompdump
   compinit
   ```

4. **For Bash**: Reload bashrc
   ```bash
   source ~/.bashrc
   ```

### No packages showing up

- **For `add`**: Make sure you have Git dependencies in your `pubspec.yaml`
- **For `remove`**: Make sure you have packages in `dependency_overrides`

## Contributing

If you find issues with the completion scripts or have suggestions for improvements, please open an issue or pull request on the DMU repository.
