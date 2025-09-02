import 'dart:io';

import 'package:syncpack/src/console/console_confirm.dart';

import '../console/console_logger.dart';

/// Gestor da pasta onde os repositorios serão clonados
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

  /// Adiciona um caminho ao .gitignore
  void addPackageToGitignore(String path) {
    final gitignoreFile = File('$projectRoot/.gitignore');

    final ignorePath = '${path.replaceAll('$projectRoot/', '')}/';

    if (_checkPathInGitignore(gitignoreFile, ignorePath)) {
      return;
    }

    if (!ConsoleConfirm.ask(
      "Gostaria de adicionar $ignorePath ao .gitignore?",
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

    ConsoleLogger.info('Adicionado $path ao .gitignore');
  }

  /// Verifica se um arquivo existe
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Cria um diretório se não existir
  void ensureDirectoryExists(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Remove um diretório se estiver vazio
  void removeEmptyDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      final contents = dir.listSync();
      if (contents.isEmpty) {
        dir.deleteSync();
      }
    }
  }

  /// Obtém o caminho absoluto de um arquivo
  String getAbsolutePath(String relativePath) {
    return File('$projectRoot/$relativePath').absolute.path;
  }

  /// Limpa todas as entradas relacionadas a package do .gitignore
  void clearPackagesFromGitignore() {
    final gitignoreFile = File('$projectRoot/.gitignore');

    if (!gitignoreFile.existsSync()) {
      return;
    }

    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    // Remove todas as linhas que começam com 'package/'
    final filteredLines = lines
        .where((line) => !line.trim().startsWith('package/'))
        .toList();

    if (filteredLines.length != lines.length) {
      gitignoreFile.writeAsStringSync(filteredLines.join('\n'));
      ConsoleLogger.info(
        'Todas as entradas de package foram removidas do .gitignore',
      );
    }
  }
}
