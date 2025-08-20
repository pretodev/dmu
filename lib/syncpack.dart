import 'dart:io';

import 'package:process/process.dart';

import 'src/console_logger.dart';
import 'src/file_manager.dart';
import 'src/git_manager.dart';
import 'src/git_package.dart';
import 'src/interactive_menu.dart';
import 'src/pubspec_parser.dart';

export 'src/console_logger.dart';
export 'src/file_manager.dart';
export 'src/git_manager.dart';
export 'src/git_package.dart';
export 'src/interactive_menu.dart';
export 'src/pubspec_parser.dart';

/// Classe principal que orquestra todas as operações do Syncpack
class Syncpack {
  /// Verifica se o projeto é válido (contém pubspec.yaml)
  static bool isValidProject(String projectRoot) {
    return File('$projectRoot/pubspec.yaml').existsSync();
  }

  /// Cria uma instância do Syncpack para o diretório atual
  static Syncpack forCurrentDirectory() {
    final currentDir = Directory.current.path;
    if (!isValidProject(currentDir)) {
      ConsoleLogger.error('pubspec.yaml não encontrado no diretório atual');
    }
    return Syncpack(projectRoot: currentDir);
  }

  final String projectRoot;
  final String packagesDir;
  final PubspecParser _pubspecParser;
  final GitManager _gitManager;
  final FileManager _fileManager;

  Syncpack({
    required this.projectRoot,
    String? packagesDir,
    ProcessManager? processManager,
  }) : packagesDir = packagesDir ?? '$projectRoot/packages',
       _pubspecParser = PubspecParser(pubspecPath: '$projectRoot/pubspec.yaml'),
       _gitManager = GitManager(
         packagesDir: packagesDir ?? '$projectRoot/packages',
         processManager: processManager,
       ),
       _fileManager = FileManager(projectRoot: projectRoot);

  /// Executa o fluxo principal do Syncpack
  Future<void> run() async {
    try {
      if (!await _gitManager.isGitAvailable()) {
        ConsoleLogger.error(
          'Git não está instalado ou não está disponível no PATH',
        );
      }

      final gitPackages = _pubspecParser.parseGitDependencies();
      if (gitPackages.isEmpty) {
        ConsoleLogger.info('Nenhum pacote Git encontrado no pubspec.yaml');
        return;
      }

      final existingOverrides = _pubspecParser.parseExistingOverrides();

      final selectedPackages =
          InteractiveMenu(
            packages: gitPackages,
            existingOverrides: existingOverrides,
          ).show();

      await _gitManager.processSelection(
        allPackages: gitPackages,
        selectedPackages: selectedPackages,
        existingOverrides: existingOverrides,
      );

      _fileManager.updateGitignore(
        allPackages: gitPackages,
        selectedPackages: selectedPackages,
        existingOverrides: existingOverrides,
        packagesDir: packagesDir,
      );

      _pubspecParser.updateDependencyOverrides(selectedPackages, packagesDir);

      await _runFlutterCommands(selectedPackages);
      ConsoleLogger.success('Sincronização concluída!');
    } catch (e) {
      ConsoleLogger.error('Erro durante a execução: $e');
    }
  }

  /// Executa comandos Flutter clean e pub get
  Future<void> _runFlutterCommands(List<GitPackage> selectedPackages) async {
    final processManager = const LocalProcessManager();
    final useFvm = _shouldUseFvm();
    final flutterCommand = useFvm ? 'fvm' : 'flutter';

    try {
      // Primeiro executa clean e pub get em cada pacote selecionado
      for (final package in selectedPackages) {
        final packageName = package.repositoryName;
        final packagePath = '$packagesDir/$packageName';
        final packageDir = Directory(packagePath);
        
        if (!packageDir.existsSync()) {
          ConsoleLogger.warning('Diretório do pacote $packageName não encontrado: $packagePath');
          continue;
        }

        ConsoleLogger.info('Executando comandos Flutter no pacote: $packageName');
        
        // Flutter clean no pacote
        ConsoleLogger.info('  Executando ${useFvm ? 'fvm flutter' : 'flutter'} clean em $packageName...');
        final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
        final cleanResult = await processManager.run([
          flutterCommand,
          ...cleanArgs,
        ], workingDirectory: packagePath);

        if (cleanResult.exitCode != 0) {
          ConsoleLogger.warning('  Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} clean em $packageName');
          continue;
        }

        // Flutter pub get no pacote
        ConsoleLogger.info('  Executando ${useFvm ? 'fvm flutter' : 'flutter'} pub get em $packageName...');
        final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
        final pubGetResult = await processManager.run([
          flutterCommand,
          ...pubGetArgs,
        ], workingDirectory: packagePath);

        if (pubGetResult.exitCode != 0) {
          ConsoleLogger.warning('  Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} pub get em $packageName');
          continue;
        }

        ConsoleLogger.success('  Comandos Flutter executados com sucesso em $packageName');
      }

      // Depois executa clean e pub get no projeto raiz
      ConsoleLogger.info('Executando comandos Flutter no projeto raiz...');
      
      ConsoleLogger.info('Executando ${useFvm ? 'fvm flutter' : 'flutter'} clean...');
      final cleanArgs = useFvm ? ['flutter', 'clean'] : ['clean'];
      final cleanResult = await processManager.run([
        flutterCommand,
        ...cleanArgs,
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.error('Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} clean no projeto raiz');
      }

      ConsoleLogger.info('Executando ${useFvm ? 'fvm flutter' : 'flutter'} pub get...');
      final pubGetArgs = useFvm ? ['flutter', 'pub', 'get'] : ['pub', 'get'];
      final pubGetResult = await processManager.run([
        flutterCommand,
        ...pubGetArgs,
      ], workingDirectory: projectRoot);

      if (pubGetResult.exitCode != 0) {
        ConsoleLogger.error('Falha ao executar ${useFvm ? 'fvm flutter' : 'flutter'} pub get no projeto raiz');
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
}
