import 'dart:io';

import 'package:process/process.dart';

import 'src/console_logger.dart';
import 'src/file_manager.dart';
import 'src/git_manager.dart';
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

      await _runFlutterCommands();
      ConsoleLogger.success('Sincronização concluída!');
    } catch (e) {
      ConsoleLogger.error('Erro durante a execução: $e');
    }
  }

  /// Executa comandos Flutter clean e pub get
  Future<void> _runFlutterCommands() async {
    final processManager = const LocalProcessManager();

    try {
      ConsoleLogger.info('Executando flutter clean...');
      final cleanResult = await processManager.run([
        'flutter',
        'clean',
      ], workingDirectory: projectRoot);

      if (cleanResult.exitCode != 0) {
        ConsoleLogger.error('Falha ao executar flutter clean');
      }

      ConsoleLogger.info('Executando flutter pub get...');
      final pubGetResult = await processManager.run([
        'flutter',
        'pub',
        'get',
      ], workingDirectory: projectRoot);

      if (pubGetResult.exitCode != 0) {
        ConsoleLogger.error('Falha ao executar flutter pub get');
      }

      ConsoleLogger.success('Comandos Flutter executados com sucesso');
    } catch (e) {
      ConsoleLogger.error('Erro ao executar comandos Flutter: $e');
    }
  }
}
