import 'dart:io';

import 'package:process/process.dart';

import '../console/console_logger.dart';
import 'git_package.dart';

/// Manages Git operations (clone, removal)
class GitManager {
  final ProcessManager _processManager;
  final String packagesDir;

  GitManager({
    required this.packagesDir,
    ProcessManager? processManager,
  }) : _processManager = processManager ?? const LocalProcessManager();

  /// Clones a Git repository
  Future<bool> cloneRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (repoDir.existsSync()) {
      ConsoleLogger.info(
        'Repository ${package.repositoryName} already exists, skipping clone',
      );
      return true;
    }

    final packagesDirectory = Directory(packagesDir);
    if (!packagesDirectory.existsSync()) {
      packagesDirectory.createSync(recursive: true);
    }

    ConsoleLogger.info('Cloning ${package.repositoryName}...');
    if (await _tryClone(package.sshUrl, package.ref, repoDir.path)) {
      ConsoleLogger.success('${package.repositoryName} cloned via SSH');
      return true;
    }

    ConsoleLogger.info('SSH failed, trying HTTPS...');
    if (await _tryClone(package.url, package.ref, repoDir.path)) {
      ConsoleLogger.success('${package.repositoryName} cloned via HTTPS');
      return true;
    }

    return false;
  }

  /// Removes a cloned repository
  Future<bool> removeRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (!repoDir.existsSync()) return true;

    try {
      ConsoleLogger.info('Removing ${package.repositoryName}...');
      repoDir.deleteSync(recursive: true);
      ConsoleLogger.success('${package.repositoryName} removed');
      return true;
    } catch (e) {
      ConsoleLogger.error('Failed to remove ${package.repositoryName}: $e');
    }
  }

  /// Updates a cloned repository (git pull)
  Future<bool> updateRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (!repoDir.existsSync()) {
      ConsoleLogger.error(
        'Repository ${package.repositoryName} does not exist',
      );
    }

    try {
      ConsoleLogger.info('Updating ${package.repositoryName}...');
      final result = await _processManager.run([
        'git',
        'pull',
      ], workingDirectory: repoDir.path);

      if (result.exitCode == 0) {
        ConsoleLogger.success('${package.repositoryName} updated');
        return true;
      }
      ConsoleLogger.error('Failed to update ${package.repositoryName}');
    } catch (e) {
      ConsoleLogger.error('Error updating ${package.repositoryName}: $e');
    }
  }

  /// Clones a repository to a custom path
  Future<bool> cloneRepositoryToPath(
    GitPackage package,
    String customPath,
  ) async {
    final repoDir = Directory('$customPath/${package.repositoryName}');

    if (repoDir.existsSync()) {
      ConsoleLogger.info(
        'Repository ${package.repositoryName} already exists at $customPath, skipping clone',
      );
      return true;
    }

    final customDirectory = Directory(customPath);
    if (!customDirectory.existsSync()) {
      customDirectory.createSync(recursive: true);
    }

    ConsoleLogger.info('Cloning ${package.repositoryName} to $customPath...');
    if (await _tryClone(package.sshUrl, package.ref, repoDir.path)) {
      ConsoleLogger.success(
        '${package.repositoryName} cloned via SSH to $customPath',
      );
      return true;
    }

    ConsoleLogger.info('SSH failed, trying HTTPS...');
    if (await _tryClone(package.url, package.ref, repoDir.path)) {
      ConsoleLogger.success(
        '${package.repositoryName} cloned via HTTPS to $customPath',
      );
      return true;
    }

    ConsoleLogger.error(
      'Failed to clone ${package.repositoryName} to $customPath',
    );
  }

  /// Removes a repository from a custom path
  Future<bool> removeRepositoryFromPath(
    GitPackage package,
    String customPath,
  ) async {
    final repoDir = Directory('$customPath/${package.repositoryName}');

    if (!repoDir.existsSync()) return true;

    try {
      ConsoleLogger.info(
        'Removing ${package.repositoryName} from $customPath...',
      );
      repoDir.deleteSync(recursive: true);
      ConsoleLogger.success(
        '${package.repositoryName} removed from $customPath',
      );
      return true;
    } catch (e) {
      ConsoleLogger.error(
        'Failed to remove ${package.repositoryName} from $customPath: $e',
      );
    }
  }

  /// Tries to clone a repository
  Future<bool> _tryClone(String url, String ref, String targetPath) async {
    try {
      final result = await _processManager.run([
        'git',
        'clone',
        '--branch',
        ref,
        '--single-branch',
        url,
        targetPath,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Checks if Git is available on the system
  Future<bool> isGitAvailable() async {
    try {
      final result = await _processManager.run(['git', '--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Cleans up packages directory if empty
  void cleanupPackagesDir() {
    final dir = Directory(packagesDir);
    if (dir.existsSync()) {
      final contents = dir.listSync();
      if (contents.isEmpty) {
        dir.deleteSync();
        ConsoleLogger.info('Packages directory removed (was empty)');
      }
    }
  }
}
