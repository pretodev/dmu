import 'dart:io';

import 'package:process/process.dart';

import 'src/console/console_logger.dart';
import 'src/git/git_manager.dart';
import 'src/git/git_package.dart';
import 'src/io/file_manager.dart';
import 'src/io/file_remover.dart';
import 'src/io/file_searcher.dart';
import 'src/io/pubspec_parser.dart';

class DartMultiRepoUtility {
  final String projectRoot;
  final String packagesDir;
  final PubspecParser _pubspecParser;
  final GitManager _gitManager;
  final FileManager _fileManager;
  final FileSearcher _fileSearcher;
  final FileRemover _fileRemover;

  DartMultiRepoUtility._(
    this.projectRoot,
    this.packagesDir,
    this._pubspecParser,
    this._gitManager,
    this._fileManager,
    this._fileSearcher,
    this._fileRemover,
  );

  factory DartMultiRepoUtility.forDirectory(
    String projectRoot, {
    String packagesSubdir = 'packages',
  }) {
    final packagesDir = '$projectRoot/$packagesSubdir';
    final pubspecPath = '$projectRoot/pubspec.yaml';

    return DartMultiRepoUtility._(
      projectRoot,
      packagesDir,
      PubspecParser(pubspecPath: pubspecPath),
      GitManager(packagesDir: packagesDir),
      FileManager(projectRoot: projectRoot),
      FileSearcher(projectRoot: projectRoot),
      FileRemover(projectRoot: projectRoot),
    );
  }

  factory DartMultiRepoUtility.forCurrentDirectory({
    String packagesSubdir = 'packages',
  }) {
    final currentDir = Directory.current.path;
    return DartMultiRepoUtility.forDirectory(
      currentDir,
      packagesSubdir: packagesSubdir,
    );
  }

  /// Adds a package to dependency_override and clones locally
  Future<void> add(String packageName) async {
    try {
      if (!await _gitManager.isGitAvailable()) {
        ConsoleLogger.error('Git is not installed or not available in PATH');
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      final package =
          gitPackages.where((p) => p.name == packageName).firstOrNull;

      if (package == null) {
        ConsoleLogger.error(
          'Package "$packageName" not found in dependencies or is not a Git repository',
        );
      }

      ConsoleLogger.info('Adding package: $packageName');
      final cloned = await _gitManager.cloneRepository(package);
      if (!cloned) {
        ConsoleLogger.error('Error cloning package: $packageName');
      }

      _pubspecParser.addSingleDependencyOverride(package, packagesDir);

      await _runFlutterCommands([package]);

      _fileManager.addPackageToGitignore(packagesDir);

      ConsoleLogger.success('Package "$packageName" added successfully!');
    } catch (e) {
      ConsoleLogger.error('Error adding package: $e');
    }
  }

  /// Removes a package from dependency_override and local folder
  Future<void> remove(String packageName) async {
    try {
      final existingOverrides = _pubspecParser.parseExistingOverrides();
      if (!existingOverrides.contains(packageName)) {
        ConsoleLogger.warning(
          'Package "$packageName" is not in dependency_overrides',
        );
        return;
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      final package =
          gitPackages.where((p) => p.name == packageName).firstOrNull;

      if (package == null) {
        ConsoleLogger.error(
          'Package "$packageName" not found in dependencies or is not a Git repository',
        );
      }

      ConsoleLogger.info('Removing package: $packageName');
      _pubspecParser.removeSingleDependencyOverride(packageName);

      final packagePath = '$packagesDir/${package.repositoryName}';
      final packageDir = Directory(packagePath);
      if (packageDir.existsSync()) {
        await packageDir.delete(recursive: true);
        ConsoleLogger.info('Package folder removed: $packagePath');
      }

      await _runFlutterCommands();

      ConsoleLogger.success('Package "$packageName" removed successfully!');
    } catch (e) {
      ConsoleLogger.error('Error removing package: $e');
    }
  }

  /// Executes Flutter clean and pub get commands
  Future<void> _runFlutterCommands([
    List<GitPackage> packages = const [],
  ]) async {
    final processManager = const LocalProcessManager();
    final useFvm = _shouldUseFvm();
    final flutterCommand = useFvm ? 'fvm' : 'flutter';

    try {
      for (final package in packages) {
        final packageName = package.repositoryName;
        final packagePath = '$packagesDir/$packageName';
        final packageDir = Directory(packagePath);

        if (!packageDir.existsSync()) {
          ConsoleLogger.warning(
            'Package directory $packageName not found: $packagePath',
          );
          continue;
        }

        ConsoleLogger.info('Setting up package: $packageName');

        ConsoleLogger.info(' ${useFvm ? 'fvm flutter' : 'flutter'} clean');
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: packagePath);

        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} clean\n${cleanResult.stderr}',
          );
          continue;
        }

        ConsoleLogger.info(' ${useFvm ? 'fvm flutter' : 'flutter'} pub get');
        final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
        final pubGetResult = await processManager.run([
          flutterCommand,
          ...pubGetArgs,
        ], workingDirectory: packagePath);

        if (pubGetResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} pub get\n${pubGetResult.stderr}',
          );
          continue;
        }
      }

      ConsoleLogger.info('Setting up root project');

      ConsoleLogger.info('  ${useFvm ? 'fvm flutter' : 'flutter'} clean');
      final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
      final cleanResult = await processManager.run([
        flutterCommand,
        ...cleanArgs,
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.warning(
          'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} clean\n${cleanResult.stderr}',
        );
      }

      ConsoleLogger.info('  ${useFvm ? 'fvm flutter' : 'flutter'} pub get');
      final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
      final pubGetResult = await processManager.run([
        flutterCommand,
        ...pubGetArgs,
      ], workingDirectory: projectRoot);

      if (pubGetResult.exitCode != 0) {
        ConsoleLogger.warning(
          'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} pub get\n${pubGetResult.stderr}',
        );
      }
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comandos Flutter: $e');
    }
  }

  /// Checks if fvm should be used based on .fvmrc file existence
  bool _shouldUseFvm() {
    final fvmrcFile = File('$projectRoot/.fvmrc');
    return fvmrcFile.existsSync();
  }

  /// Executa flutter clean e pub get em todos os pacotes de dependency_overrides
  Future<void> pubGet() async {
    try {
      final isFdAvailable = await _fileSearcher.isFdAvailable();
      if (!isFdAvailable) {
        ConsoleLogger.error('fd is not installed.');
      }

      final projects = await _fileSearcher.availablesDartProjects();
      if (projects.isEmpty) {
        return;
      }

      final processManager = const LocalProcessManager();
      final useFvm = _shouldUseFvm();
      final flutterCommand = useFvm ? 'fvm' : 'flutter';

      ConsoleLogger.info('Downloading dependencies...');
      for (final project in projects) {
        final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
        final pubGetResult = await processManager.run([
          flutterCommand,
          ...pubGetArgs,
        ], workingDirectory: project);
        if (pubGetResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} pub get in $project\n${pubGetResult.stderr}',
          );
          continue;
        }
      }
    } catch (e) {
      ConsoleLogger.error('Error executing get command: $e');
    }
  }

  /// Completely cleans project dependencies
  Future<void> clean({bool deep = false}) async {
    try {
      final isFdAvailable = await _fileSearcher.isFdAvailable();
      if (!isFdAvailable) {
        ConsoleLogger.error('fd is not installed.');
      }

      final projects = await _fileSearcher.availablesDartProjects();
      if (projects.isEmpty) {
        return;
      }

      if (deep) {
        final lockFiles =
            projects.map((path) => '${path}pubspec.lock').toList();
        await _fileRemover.remove(lockFiles);
      }

      final processManager = const LocalProcessManager();
      final useFvm = _shouldUseFvm();
      final flutterCommand = useFvm ? 'fvm' : 'flutter';

      ConsoleLogger.info('Cleaning dependencies...');
      for (final project in projects) {
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: project);
        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Failed: ${useFvm ? 'fvm flutter' : 'flutter'} clean in $project\n${cleanResult.stderr}',
          );
          continue;
        }
      }
    } catch (e) {
      ConsoleLogger.error('Error executing clean command: $e');
    }
  }

  /// Returns a list of package names that can be added (Git dependencies not yet in overrides)
  List<String> getAvailablePackages() {
    final gitPackages = _pubspecParser.parseGitDependencies();
    final existingOverrides = _pubspecParser.parseExistingOverrides();

    return gitPackages
        .where((package) => !existingOverrides.contains(package.name))
        .map((package) => package.name)
        .toList();
  }
}
