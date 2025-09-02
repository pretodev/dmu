import 'dart:io';

import 'package:process/process.dart';

import 'src/console_logger.dart';
import 'src/file_manager.dart';
import 'src/git_manager.dart';
import 'src/git_package.dart';
import 'src/package_usage_checker.dart';
import 'src/pubspec_parser.dart';

class Syncpack {
  final String projectRoot;
  final String packagesDir;
  final PubspecParser _pubspecParser;
  final GitManager _gitManager;
  final FileManager _fileManager;
  final PackageUsageChecker _usageChecker;

  Syncpack._(
    this.projectRoot,
    this.packagesDir,
    this._pubspecParser,
    this._gitManager,
    this._fileManager,
    this._usageChecker,
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
      PackageUsageChecker(projectRoot: projectRoot),
    );
  }

  factory Syncpack.forCurrentDirectory({String packagesSubdir = 'packages'}) {
    final currentDir = Directory.current.path;
    return Syncpack.forDirectory(currentDir, packagesSubdir: packagesSubdir);
  }

  /// Adiciona um pacote ao dependency_override e clona localmente
  Future<void> add(String packageName, {String clonePath = 'packages'}) async {
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

      final targetDir = clonePath == 'packages'
          ? packagesDir
          : '$projectRoot/$clonePath';

      ConsoleLogger.info('Adicionando pacote: $packageName');
      await _gitManager.cloneRepository(package);
      _pubspecParser.addSingleDependencyOverride(package, targetDir);

      // TODO: Gostaria de adicionar .gitignore
      // Atualiza .gitignore
      // final customPath = clonePath == 'package'
      //     ? null
      //     : '$clonePath/${package.repositoryName}';
      // _fileManager.addPackageToGitignore(
      //   packageName,
      //   package.repositoryName,
      //   customPath: customPath,
      // );

      // Executa flutter clean e pub get no pacote e projeto
      await _runFlutterCommands([package], customPackagesDir: targetDir);

      ConsoleLogger.success('Pacote "$packageName" adicionado com sucesso!');
    } catch (e) {
      ConsoleLogger.error('Erro ao adicionar pacote: $e');
    }
  }

  /// Remove um pacote do dependency_override e pasta local
  Future<void> remove(String packageName) async {
    try {
      final gitPackages = _pubspecParser.parseGitDependencies();
      final package = gitPackages
          .where((p) => p.name == packageName)
          .firstOrNull;

      if (package == null) {
        ConsoleLogger.error(
          'Pacote "$packageName" não encontrado nas dependencies ou não é um repositório Git',
        );
      }

      final existingOverrides = _pubspecParser.parseExistingOverrides();
      if (!existingOverrides.contains(packageName)) {
        ConsoleLogger.warning(
          'Pacote "$packageName" não está no dependency_overrides',
        );
      }

      // Verifica se o pacote está sendo usado (busca por imports)
      if (_usageChecker.isPackageInUse(packageName)) {
        ConsoleLogger.error(
          'Pacote "$packageName" está sendo usado no projeto. Remova as referências antes de continuar.',
        );
      }

      ConsoleLogger.info('Removendo pacote: $packageName');

      // Remove do dependency_overrides
      _pubspecParser.removeSingleDependencyOverride(packageName);

      // Remove pasta do clone
      final packagePath = '$packagesDir/${package.repositoryName}';
      final packageDir = Directory(packagePath);
      if (packageDir.existsSync()) {
        await packageDir.delete(recursive: true);
        ConsoleLogger.info('Pasta do pacote removida: $packagePath');
      }

      // Atualiza .gitignore
      _fileManager.removePackageFromGitignore(
        packageName,
        package.repositoryName,
      );

      // Executa flutter clean e pub get no projeto
      await _runFlutterCommandsInProject();

      ConsoleLogger.success('Pacote "$packageName" removido com sucesso!');
    } catch (e) {
      ConsoleLogger.error('Erro ao remover pacote: $e');
    }
  }

  /// Atualiza um ou todos os pacotes
  Future<void> update({String? packageName, bool cleanLock = false}) async {
    try {
      if (!await _gitManager.isGitAvailable()) {
        ConsoleLogger.error(
          'Git não está instalado ou não está disponível no PATH',
        );
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      final existingOverrides = _pubspecParser.parseExistingOverrides();

      List<GitPackage> packagesToUpdate;

      if (packageName != null) {
        // Atualiza pacote específico
        final package = gitPackages
            .where((p) => p.name == packageName)
            .firstOrNull;
        if (package == null) {
          ConsoleLogger.error(
            'Pacote "$packageName" não encontrado nas dependencies ou não é um repositório Git',
          );
        }
        if (!existingOverrides.contains(packageName)) {
          ConsoleLogger.error(
            'Pacote "$packageName" não está no dependency_overrides',
          );
        }
        packagesToUpdate = [package];
        ConsoleLogger.info('Atualizando pacote: $packageName');
      } else {
        // Atualiza todos os pacotes que estão no dependency_overrides
        packagesToUpdate = gitPackages
            .where((p) => existingOverrides.contains(p.name))
            .toList();
        if (packagesToUpdate.isEmpty) {
          ConsoleLogger.info('Nenhum pacote para atualizar');
        }
        ConsoleLogger.info('Atualizando ${packagesToUpdate.length} pacote(s)');
      }

      // Remove pubspec.lock se solicitado
      if (cleanLock) {
        final lockFile = File('$projectRoot/pubspec.lock');
        if (lockFile.existsSync()) {
          await lockFile.delete();
          ConsoleLogger.info('pubspec.lock removido');
        }
      }

      // Atualiza os repositórios (git pull)
      for (final package in packagesToUpdate) {
        await _gitManager.updateRepository(package);
      }

      // Executa flutter clean e pub get nos pacotes e projeto
      await _runFlutterCommands(packagesToUpdate);

      ConsoleLogger.success('Atualização concluída!');
    } catch (e) {
      ConsoleLogger.error('Erro ao atualizar pacote(s): $e');
    }
  }

  /// Executa comandos Flutter clean e pub get
  Future<void> _runFlutterCommands(
    List<GitPackage> selectedPackages, {
    String? customPackagesDir,
  }) async {
    final processManager = const LocalProcessManager();
    final useFvm = _shouldUseFvm();
    final flutterCommand = useFvm ? 'fvm' : 'flutter';

    try {
      // Primeiro executa clean e pub get em cada pacote selecionado
      for (final package in selectedPackages) {
        final packageName = package.repositoryName;
        final packagePath = '${customPackagesDir ?? packagesDir}/$packageName';
        final packageDir = Directory(packagePath);

        if (!packageDir.existsSync()) {
          ConsoleLogger.warning(
            'Diretório do pacote $packageName não encontrado: $packagePath',
          );
          continue;
        }

        ConsoleLogger.info(
          'Executando comandos Flutter no pacote: $packageName',
        );

        // Flutter clean no pacote
        ConsoleLogger.info(
          '  Executando ${useFvm ? 'fvm flutter' : 'flutter'} clean em $packageName...',
        );
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: packagePath);

        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning(
            '  Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} clean em $packageName',
          );
          continue;
        }

        // Flutter pub get no pacote
        ConsoleLogger.info(
          '  Executando ${useFvm ? 'fvm flutter' : 'flutter'} pub get em $packageName...',
        );
        final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
        final pubGetResult = await processManager.run([
          flutterCommand,
          ...pubGetArgs,
        ], workingDirectory: packagePath);

        if (pubGetResult.exitCode != 0) {
          ConsoleLogger.warning(
            '  Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} pub get em $packageName',
          );
          continue;
        }

        ConsoleLogger.success(
          '  Comandos Flutter executados com sucesso em $packageName',
        );
      }

      // Depois executa clean e pub get no projeto raiz
      ConsoleLogger.info('Executando comandos Flutter no projeto raiz...');

      ConsoleLogger.info(
        'Executando ${useFvm ? 'fvm flutter' : 'flutter'} clean...',
      );
      final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
      final cleanResult = await processManager.run([
        flutterCommand,
        ...cleanArgs,
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.error(
          'Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} clean no projeto raiz',
        );
      }

      ConsoleLogger.info(
        'Executando ${useFvm ? 'fvm flutter' : 'flutter'} pub get...',
      );
      final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
      final pubGetResult = await processManager.run([
        flutterCommand,
        ...pubGetArgs,
      ], workingDirectory: projectRoot);

      if (pubGetResult.exitCode != 0) {
        ConsoleLogger.error(
          'Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} pub get no projeto raiz',
        );
      }

      ConsoleLogger.success('Todos os comandos Flutter executados com sucesso');
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comandos Flutter: $e');
    }
  }

  /// Verifica se deve usar fvm baseado na existência do arquivo .fvmrc
  bool _shouldUseFvm() {
    final fvmrcFile = File('$projectRoot/.fvmrc');
    return fvmrcFile.existsSync();
  }

  /// Limpa completamente tudo: remove packages/, dependency_overrides e entradas do .gitignore
  Future<void> cleanAll() async {
    ConsoleLogger.info('Iniciando limpeza completa...');

    try {
      // Remove o diretório packages/ se existir
      final packagesDirectory = Directory(packagesDir);
      if (packagesDirectory.existsSync()) {
        ConsoleLogger.info('Removendo diretório packages/...');
        await packagesDirectory.delete(recursive: true);
        ConsoleLogger.success('Diretório packages/ removido');
      } else {
        ConsoleLogger.info('Diretório packages/ não existe');
      }

      // Limpa todos os dependency_overrides do pubspec.yaml
      ConsoleLogger.info('Limpando dependency_overrides do pubspec.yaml...');
      _pubspecParser.clearAllDependencyOverrides();
      ConsoleLogger.success('dependency_overrides limpos');

      // Limpa entradas relacionadas no .gitignore
      ConsoleLogger.info('Limpando entradas do .gitignore...');
      _fileManager.clearPackagesFromGitignore();
      ConsoleLogger.success('Entradas do .gitignore limpas');
    } catch (e) {
      ConsoleLogger.error('Erro durante a limpeza: $e');
    }
  }

  /// Executa flutter clean e pub get apenas no projeto raiz
  Future<void> _runFlutterCommandsInProject() async {
    final processManager = const LocalProcessManager();
    final useFvm = _shouldUseFvm();
    final flutterCommand = useFvm ? 'fvm' : 'flutter';

    try {
      ConsoleLogger.info('Executando comandos Flutter no projeto raiz...');

      ConsoleLogger.info(
        'Executando ${useFvm ? 'fvm flutter' : 'flutter'} clean...',
      );
      final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
      final cleanResult = await processManager.run([
        flutterCommand,
        ...cleanArgs,
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.error(
          'Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} clean no projeto raiz',
        );
      }

      ConsoleLogger.info(
        'Executando ${useFvm ? 'fvm flutter' : 'flutter'} pub get...',
      );
      final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
      final pubGetResult = await processManager.run([
        flutterCommand,
        ...pubGetArgs,
      ], workingDirectory: projectRoot);

      if (pubGetResult.exitCode != 0) {
        ConsoleLogger.error(
          'Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} pub get no projeto raiz',
        );
      }

      ConsoleLogger.success(
        'Comandos Flutter executados com sucesso no projeto raiz',
      );
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comandos Flutter no projeto: $e');
    }
  }
}
