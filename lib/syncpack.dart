import 'dart:io';

import 'package:process/process.dart';
import 'package:syncpack/src/io/file_searcher.dart';

import 'src/console/console_logger.dart';
import 'src/git/git_manager.dart';
import 'src/git/git_package.dart';
import 'src/io/file_manager.dart';
import 'src/io/pubspec_parser.dart';

class Syncpack {
  final String projectRoot;
  final String packagesDir;
  final PubspecParser _pubspecParser;
  final GitManager _gitManager;
  final FileManager _fileManager;
  final FileSearcher _fileSearcher;

  Syncpack._(
    this.projectRoot,
    this.packagesDir,
    this._pubspecParser,
    this._gitManager,
    this._fileManager,
    this._fileSearcher,
  );

  factory Syncpack.forDirectory(
    String projectRoot, {
    String packagesSubdir = 'packages',
  }) {
    final packagesDir = '$projectRoot/$packagesSubdir';
    final pubspecPath = '$projectRoot/pubspec.yaml';

    return Syncpack._(
      projectRoot,
      packagesDir,
      PubspecParser(pubspecPath: pubspecPath),
      GitManager(packagesDir: packagesDir),
      FileManager(projectRoot: projectRoot),
      FileSearcher(projectRoot: projectRoot),
    );
  }

  factory Syncpack.forCurrentDirectory({String packagesSubdir = 'packages'}) {
    final currentDir = Directory.current.path;
    return Syncpack.forDirectory(currentDir, packagesSubdir: packagesSubdir);
  }

  /// Adiciona um pacote ao dependency_override e clona localmente
  Future<void> add(String packageName) async {
    try {
      if (!await _gitManager.isGitAvailable()) {
        ConsoleLogger.error(
          'Git não está instalado ou não está disponível no PATH',
        );
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      final package = gitPackages
          .where((p) => p.name == packageName)
          .firstOrNull;

      if (package == null) {
        ConsoleLogger.error(
          'Pacote "$packageName" não encontrado nas dependencies ou não é um repositório Git',
        );
      }

      ConsoleLogger.info('Adicionando pacote: $packageName');
      final cloned = await _gitManager.cloneRepository(package);
      if (!cloned) {
        ConsoleLogger.error('Erro ao clonar pacote: $packageName');
      }

      _pubspecParser.addSingleDependencyOverride(package, packagesDir);

      await _runFlutterCommands([package]);

      _fileManager.addPackageToGitignore(packagesDir);

      ConsoleLogger.success('Pacote "$packageName" adicionado com sucesso!');
    } catch (e) {
      ConsoleLogger.error('Erro ao adicionar pacote: $e');
    }
  }

  /// Remove um pacote do dependency_override e pasta local
  Future<void> remove(String packageName) async {
    try {
      final existingOverrides = _pubspecParser.parseExistingOverrides();
      if (!existingOverrides.contains(packageName)) {
        ConsoleLogger.warning(
          'Pacote "$packageName" não está no dependency_overrides',
        );
        return;
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      final package = gitPackages
          .where((p) => p.name == packageName)
          .firstOrNull;

      if (package == null) {
        ConsoleLogger.error(
          'Pacote "$packageName" não encontrado nas dependencies ou não é um repositório Git',
        );
      }

      ConsoleLogger.info('Removendo pacote: $packageName');
      _pubspecParser.removeSingleDependencyOverride(packageName);

      final packagePath = '$packagesDir/${package.repositoryName}';
      final packageDir = Directory(packagePath);
      if (packageDir.existsSync()) {
        await packageDir.delete(recursive: true);
        ConsoleLogger.info('Pasta do pacote removida: $packagePath');
      }

      await _runFlutterCommands();

      ConsoleLogger.success('Pacote "$packageName" removido com sucesso!');
    } catch (e) {
      ConsoleLogger.error('Erro ao remover pacote: $e');
    }
  }

  /// Executa comandos Flutter clean e pub get
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
            'Diretório do pacote $packageName não encontrado: $packagePath',
          );
          continue;
        }

        ConsoleLogger.info('Configurando pacote: $packageName');

        ConsoleLogger.info(' ${useFvm ? 'fvm flutter' : 'flutter'} clean');
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: packagePath);

        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} clean\n${cleanResult.stderr}',
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
            'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} pub get\n${pubGetResult.stderr}',
          );
          continue;
        }
      }

      ConsoleLogger.info('Configurando projeto raiz');

      ConsoleLogger.info('  ${useFvm ? 'fvm flutter' : 'flutter'} clean');
      final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
      final cleanResult = await processManager.run([
        flutterCommand,
        ...cleanArgs,
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.warning(
          'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} clean\n${cleanResult.stderr}',
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
          'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} pub get\n${pubGetResult.stderr}',
        );
      }
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comandos Flutter: $e');
    }
  }

  /// Verifica se deve usar fvm baseado na existência do arquivo .fvmrc
  bool _shouldUseFvm() {
    final fvmrcFile = File('$projectRoot/.fvmrc');
    return fvmrcFile.existsSync();
  }

  /// Executa flutter clean e pub get em todos os pacotes de dependency_overrides
  Future<void> pubGet() async {
    try {
      final isFdAvailable = await _fileSearcher.isFdAvailable();
      if (!isFdAvailable) {
        ConsoleLogger.error('fd não está instalado.');
      }

      final projects = await _fileSearcher.availablesDartProjects();
      if (projects.isEmpty) {
        return;
      }

      final processManager = const LocalProcessManager();
      final useFvm = _shouldUseFvm();
      final flutterCommand = useFvm ? 'fvm' : 'flutter';

      ConsoleLogger.info('Baixando dependências...');
      for (final project in projects) {
        final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
        final pubGetResult = await processManager.run([
          flutterCommand,
          ...pubGetArgs,
        ], workingDirectory: project);
        if (pubGetResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} pub get em $project\n${pubGetResult.stderr}',
          );
          continue;
        }
      }
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comando get: $e');
    }
  }

  /// Limpa completamente as dependências do projeto
  Future<void> clean() async {
    try {
      final isFdAvailable = await _fileSearcher.isFdAvailable();
      if (!isFdAvailable) {
        ConsoleLogger.error('fd não está instalado.');
      }

      final projects = await _fileSearcher.availablesDartProjects();
      if (projects.isEmpty) {
        return;
      }

      final processManager = const LocalProcessManager();
      final useFvm = _shouldUseFvm();
      final flutterCommand = useFvm ? 'fvm' : 'flutter';

      ConsoleLogger.info('Limpando dependências...');
      for (final project in projects) {
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: project);
        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning(
            'Falha: ${useFvm ? 'fvm flutter' : 'flutter'} clean em $project\n${cleanResult.stderr}',
          );
          continue;
        }
      }
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comando clean: $e');
    }
  }
}
