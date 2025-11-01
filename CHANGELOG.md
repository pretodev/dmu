# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0]

### Added
- Multi-provider Git URL support with extensible converter system
- Support for GitHub SSH URL conversion
- Support for GitLab SSH URL conversion (including self-hosted instances)
- Support for Bitbucket SSH URL conversion
- Support for Gitea SSH URL conversion
- Generic Git URL converter as fallback for unknown providers
- Comprehensive test suite for URL converters (43 tests)
- Documentation for Git URL converter system (`lib/src/git/README.md`)

### Changed
- Refactored URL to SSH conversion from hardcoded Azure DevOps logic to provider-based strategy pattern
- `GitPackage.sshUrl` now uses `GitUrlConverterFactory` to determine the appropriate converter

### Technical Improvements
- Implemented Strategy pattern for URL conversion
- Created `GitUrlConverter` interface for extensibility
- Added `GitUrlConverterFactory` for automatic provider detection
- Improved code maintainability by separating provider-specific logic
- Added ability to register custom converters for proprietary Git hosting solutions

## [1.0.0]

### Added
- Shell completion support for Zsh and Bash
- `completions` command to list available Git packages for shell autocomplete
- Tab-completion for package names in `add` command
- Tab-completion for package names in `remove` command
- Automatic completion script installer (`install-completions.sh`)
- Comprehensive completion documentation in `completions/README.md`
- Testing guide for shell completions in `completions/TESTING.md`

### Changed
- Help message now includes the `completions` command

## [0.1.0]

### Added
- Initial release of DMU (Dart Multi-Repo Utility)
- `add` command to clone Git dependencies locally and configure dependency overrides
- `remove` command to remove local package overrides and delete cloned directories
- `pub-get` command to run pub get on all packages in the workspace
- `clean` command to clean build artifacts from all packages
- `--deep` flag for clean command to also remove pubspec.lock files
- Automatic FVM detection and usage when `.fvmrc` file is present
- Automatic `.gitignore` management for packages directory
- Interactive confirmation prompts for destructive operations
- Comprehensive error handling and user-friendly messages
- Support for custom package directories via `--path` option
- Multi-package workspace support

### Features
- Git repository cloning and management
- Automatic dependency override configuration in pubspec.yaml
- Workspace-wide pub get execution
- Build artifact cleaning across all packages
- FVM compatibility for Flutter projects
- Safe file operations with user confirmations

[0.1.0]: https://github.com/pretodev/dmu/releases/tag/v0.1.0
