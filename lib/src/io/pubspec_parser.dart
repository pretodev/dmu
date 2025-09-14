import 'dart:io';

import 'package:yaml/yaml.dart';

import '../console/console_logger.dart';
import '../git/git_package.dart';

/// Parser for analysis and manipulation of pubspec.yaml
class PubspecParser {
  final String pubspecPath;
  late final YamlMap _yamlContent;
  late final List<String> _lines;

  PubspecParser({required this.pubspecPath}) {
    _loadPubspec();
  }

  /// Loads the content of pubspec.yaml
  void _loadPubspec() {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      ConsoleLogger.error('pubspec.yaml not found at: $pubspecPath');
    }

    final content = file.readAsStringSync();
    _lines = content.split('\n');
    _yamlContent = loadYaml(content) as YamlMap;
  }

  /// Extracts all Git packages from dependencies
  List<GitPackage> parseGitDependencies() {
    final gitPackages = <GitPackage>[];
    final dependencies = _yamlContent['dependencies'] as YamlMap?;

    if (dependencies == null) return gitPackages;

    for (final entry in dependencies.entries) {
      final packageName = entry.key as String;
      final packageConfig = entry.value;

      if (packageConfig is YamlMap && packageConfig.containsKey('git')) {
        final gitConfig = packageConfig['git'];

        if (gitConfig is String) {
          gitPackages.add(
            GitPackage(
              name: packageName,
              url: gitConfig,
              ref: 'main', // default ref
            ),
          );
        } else if (gitConfig is YamlMap) {
          final url = gitConfig['url'] as String?;
          final ref = gitConfig['ref'] as String? ?? 'main';
          final path = gitConfig['path'] as String?;

          if (url != null) {
            gitPackages.add(
              GitPackage(name: packageName, url: url, ref: ref, path: path),
            );
          }
        }
      }
    }

    return gitPackages;
  }

  /// Extracts existing overrides from pubspec.yaml
  List<String> parseExistingOverrides() {
    final overrides = <String>[];
    final dependencyOverrides =
        _yamlContent['dependency_overrides'] as YamlMap?;

    if (dependencyOverrides == null) return overrides;

    for (final entry in dependencyOverrides.entries) {
      final packageName = entry.key as String;
      overrides.add(packageName);
    }

    return overrides;
  }

  /// Extracts existing overrides with their paths from pubspec.yaml
  Map<String, String> parseExistingOverridesWithPaths() {
    final overrides = <String, String>{};
    final dependencyOverrides =
        _yamlContent['dependency_overrides'] as YamlMap?;

    if (dependencyOverrides == null) return overrides;

    for (final entry in dependencyOverrides.entries) {
      final packageName = entry.key as String;
      final packageConfig = entry.value;

      if (packageConfig is YamlMap && packageConfig.containsKey('path')) {
        final path = packageConfig['path'] as String;
        overrides[packageName] = path;
      }
    }

    return overrides;
  }

  /// Updates pubspec.yaml with new dependency_overrides
  void updateDependencyOverrides(
    List<GitPackage> selectedPackages,
    String packagesDir,
  ) {
    _removeDependencyOverrides();
    if (selectedPackages.isEmpty) {
      _writePubspec();
      return;
    }
    _addDependencyOverrides(selectedPackages, packagesDir);
    _writePubspec();
  }

  /// Removes existing dependency_overrides block from pubspec.yaml
  void _removeDependencyOverrides() {
    int? startIndex;
    int? endIndex;

    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim().startsWith('dependency_overrides:')) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == null) return;

    for (int i = startIndex + 1; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.trim().isEmpty) continue;
      if (!line.startsWith(' ') && !line.startsWith('\t')) {
        endIndex = i;
        break;
      }
    }

    endIndex ??= _lines.length;

    _lines.removeRange(startIndex, endIndex);
  }

  void _addDependencyOverrides(List<GitPackage> packages, String packagesDir) {
    final overrideLines = <String>['dependency_overrides:'];

    for (final package in packages) {
      final relativePath = package.getRelativePath();
      overrideLines.add('  ${package.name}:');
      overrideLines.add('    path: $relativePath');
    }

    if (_lines.isNotEmpty && _lines.last.trim().isNotEmpty) {
      _lines.add('');
    }

    _lines.addAll(overrideLines);
  }

  void _writePubspec() {
    final file = File(pubspecPath);
    file.writeAsStringSync(_lines.join('\n'));
  }

  /// Completely clears all dependency_overrides from pubspec.yaml
  void clearAllDependencyOverrides() {
    _removeDependencyOverrides();
    _writePubspec();
    ConsoleLogger.info(
      'All dependency_overrides have been removed from pubspec.yaml',
    );
  }

  /// Checks if a specific package exists in dependencies and is Git
  GitPackage? findGitPackage(String packageName) {
    final gitPackages = parseGitDependencies();
    try {
      return gitPackages.firstWhere((pkg) => pkg.name == packageName);
    } catch (e) {
      return null;
    }
  }

  /// Adds a single package to dependency_overrides
  /// If package already exists, replaces existing configuration
  void addSingleDependencyOverride(GitPackage package, String packagesDir) {
    final existingOverrides = parseExistingOverrides();

    if (existingOverrides.contains(package.name)) {
      ConsoleLogger.info(
        'Replacing existing configuration for package ${package.name}',
      );
      _removeSinglePackageFromOverrides(package.name);
    }

    final insertIndex = _getDependencyOverridesIndex();

    final relativePath = package.getRelativePath();
    _lines.insert(insertIndex, '  ${package.name}:');
    _lines.insert(insertIndex + 1, '    path: $relativePath');

    _writePubspec();
    ConsoleLogger.info('Added ${package.name} to dependency_overrides');
  }

  /// Removes a single package from dependency_overrides
  void removeSingleDependencyOverride(String packageName) {
    _removeSinglePackageFromOverrides(packageName);
    _writePubspec();
    ConsoleLogger.info('Removed $packageName from dependency_overrides');
  }

  int _getDependencyOverridesIndex() {
    int? insertIndex = _findDependencyOverridesInsertIndex();
    if (insertIndex != null) {
      return insertIndex;
    }
    final commentIndex = _uncommentDependencyOverrides();
    if (commentIndex != null) {
      return commentIndex + 1;
    }
    if (_lines.isNotEmpty && _lines.last.trim().isNotEmpty) {
      _lines.add('');
    }
    _lines.add('dependency_overrides:');
    return _lines.length;
  }

  /// Removes a single package from dependency_overrides without writing file
  void _removeSinglePackageFromOverrides(String packageName) {
    int? startIndex;
    int? endIndex;
    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i].trim();
      if (line == '$packageName:' && i > 0) {
        bool inOverridesBlock = false;
        for (int j = i - 1; j >= 0; j--) {
          final prevLine = _lines[j].trim();
          if (prevLine == 'dependency_overrides:') {
            inOverridesBlock = true;
            break;
          } else if (prevLine.isNotEmpty &&
              !prevLine.startsWith('#') &&
              !_lines[j].startsWith(' ')) {
            break;
          }
        }

        if (inOverridesBlock) {
          startIndex = i;
          break;
        }
      }
    }

    if (startIndex == null) {
      return;
    }

    for (int i = startIndex + 1; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.trim().isEmpty) continue;

      if (!line.startsWith('  ')) {
        endIndex = i;
        break;
      }

      if (line.startsWith('  ') &&
          !line.startsWith('    ') &&
          line.contains(':')) {
        endIndex = i;
        break;
      }
    }

    endIndex ??= _lines.length;

    _lines.removeRange(startIndex, endIndex);

    _removeEmptyDependencyOverridesBlock();
  }

  int? _findDependencyOverridesInsertIndex() {
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim().startsWith('dependency_overrides:')) {
        // Find end of block to insert
        for (int j = i + 1; j < _lines.length; j++) {
          final line = _lines[j];
          if (line.trim().isEmpty) continue;
          if (!line.startsWith(' ') && !line.startsWith('\t')) {
            return j;
          }
        }
        return _lines.length;
      }
    }
    return null;
  }

  int? _uncommentDependencyOverrides() {
    final index = _lines.indexWhere(
      (element) => element.contains('dependency_overrides:'),
    );
    if (index == -1) return null;
    _lines[index] = 'dependency_overrides:';
    return index;
  }

  void _removeEmptyDependencyOverridesBlock() {
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim() == 'dependency_overrides:') {
        bool isEmpty = true;
        for (int j = i + 1; j < _lines.length; j++) {
          final line = _lines[j];
          if (line.trim().isEmpty) continue;
          if (line.startsWith('  ') || line.startsWith('\t')) {
            isEmpty = false;
            break;
          } else {
            break;
          }
        }

        if (isEmpty) {
          _lines.removeAt(i);
          if (i > 0 && _lines[i - 1].trim().isEmpty) {
            _lines.removeAt(i - 1);
          }
        }
        break;
      }
    }
  }
}
