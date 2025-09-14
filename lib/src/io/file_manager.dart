import 'dart:io';

import '../console/console_confirm.dart';
import '../console/console_logger.dart';

/// Manager for the folder where repositories will be cloned
class FileManager {
  final String projectRoot;

  FileManager({
    required this.projectRoot,
  });

  bool _checkPathInGitignore(File gitignoreFile, path) {
    if (!gitignoreFile.existsSync()) {
      return false;
    }
    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    if (lines.any((line) => line.trim() == path)) {
      return true;
    }
    return false;
  }

  /// Adds a path to .gitignore
  void addPackageToGitignore(String path) {
    final gitignoreFile = File('$projectRoot/.gitignore');

    final ignorePath = '${path.replaceAll('$projectRoot/', '')}/';

    if (_checkPathInGitignore(gitignoreFile, ignorePath)) {
      return;
    }

    if (!ConsoleConfirm.ask(
      "Would you like to add $ignorePath to .gitignore?",
    )) {
      return;
    }

    if (!gitignoreFile.existsSync()) {
      gitignoreFile.createSync();
    }

    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    if (lines.any((line) => line.trim() == ignorePath)) {
      return;
    }

    if (content.isNotEmpty && !content.endsWith('\n')) {
      lines.add('');
    }

    lines.add(ignorePath);
    gitignoreFile.writeAsStringSync(lines.join('\n'));

    ConsoleLogger.info('Added $path to .gitignore');
  }

  /// Checks if a file exists
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Creates a directory if it doesn't exist
  void ensureDirectoryExists(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Removes a directory if it's empty
  void removeEmptyDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      final contents = dir.listSync();
      if (contents.isEmpty) {
        dir.deleteSync();
      }
    }
  }

  /// Gets the absolute path of a file
  String getAbsolutePath(String relativePath) {
    return File('$projectRoot/$relativePath').absolute.path;
  }

  /// Clears all package-related entries from .gitignore
  void clearPackagesFromGitignore() {
    final gitignoreFile = File('$projectRoot/.gitignore');

    if (!gitignoreFile.existsSync()) {
      return;
    }

    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    // Remove all lines that start with 'package/'
    final filteredLines = lines
        .where((line) => !line.trim().startsWith('package/'))
        .toList();

    if (filteredLines.length != lines.length) {
      gitignoreFile.writeAsStringSync(filteredLines.join('\n'));
      ConsoleLogger.info(
        'All package entries have been removed from .gitignore',
      );
    }
  }
}
