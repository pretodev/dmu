import 'dart:io';

import 'console_logger.dart';

/// Gerencia operações de arquivo (.gitignore)
class FileManager {
  final String projectRoot;

  FileManager({required this.projectRoot});

  /// Adiciona um pacote ao .gitignore
  void addPackageToGitignore(
    String packageName,
    String repositoryName, {
    String? customPath,
  }) {
    final gitignoreFile = File('$projectRoot/.gitignore');
    final repoPath = customPath ?? 'package/$repositoryName';

    if (!gitignoreFile.existsSync()) {
      gitignoreFile.createSync();
    }

    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    if (lines.any((line) => line.trim() == repoPath)) {
      return;
    }

    if (content.isNotEmpty && !content.endsWith('\n')) {
      lines.add('');
    }

    lines.add(repoPath);
    gitignoreFile.writeAsStringSync(lines.join('\n'));

    ConsoleLogger.info('Adicionado $repoPath ao .gitignore');
  }

  /// Remove um pacote do .gitignore
  void removePackageFromGitignore(
    String packageName,
    String repositoryName, {
    String? customPath,
  }) {
    final gitignoreFile = File('$projectRoot/.gitignore');

    if (!gitignoreFile.existsSync()) {
      return;
    }

    final repoPath = customPath ?? 'package/$repositoryName';
    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');

    // Remove a linha correspondente
    final filteredLines = lines
        .where((line) => line.trim() != repoPath)
        .toList();

    if (filteredLines.length != lines.length) {
      gitignoreFile.writeAsStringSync(filteredLines.join('\n'));
      ConsoleLogger.info('Removido $repoPath do .gitignore');
    }
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
