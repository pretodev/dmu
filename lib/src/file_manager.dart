import 'dart:io';
import 'git_package.dart';
import 'console_logger.dart';

/// Gerencia operações de arquivo (.gitignore)
class FileManager {
  final String projectRoot;
  
  FileManager({required this.projectRoot});

  /// Atualiza o .gitignore com base nos pacotes selecionados
  void updateGitignore({
    required List<GitPackage> allPackages,
    required List<GitPackage> selectedPackages,
    required List<String> existingOverrides,
    required String packagesDir,
  }) {
    final gitignoreFile = File('$projectRoot/.gitignore');
    final selectedNames = selectedPackages.map((p) => p.name).toSet();
    
    // Remove entradas de pacotes desmarcados
    for (final packageName in existingOverrides) {
      if (!selectedNames.contains(packageName)) {
        final package = allPackages.firstWhere(
          (p) => p.name == packageName,
          orElse: () => throw StateError('Pacote $packageName não encontrado'),
        );
        _removeFromGitignore(gitignoreFile, package, packagesDir);
      }
    }

    // Adiciona entradas de novos pacotes selecionados
    for (final package in selectedPackages) {
      if (!existingOverrides.contains(package.name)) {
        _addToGitignore(gitignoreFile, package, packagesDir);
      }
    }
  }

  void _addToGitignore(File gitignoreFile, GitPackage package, String packagesDir) {
    final repoPath = 'packages/${package.repositoryName}';
    
    if (!gitignoreFile.existsSync()) {
      gitignoreFile.createSync();
    }

    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');
    
    // Verifica se a entrada já existe
    if (lines.any((line) => line.trim() == repoPath)) {
      return; // Já existe
    }

    // Adiciona a entrada
    if (content.isNotEmpty && !content.endsWith('\n')) {
      lines.add('');
    }
    
    lines.add(repoPath);
    gitignoreFile.writeAsStringSync(lines.join('\n'));
    
    ConsoleLogger.info('Adicionado $repoPath ao .gitignore');
  }

  void _removeFromGitignore(File gitignoreFile, GitPackage package, String packagesDir) {
    if (!gitignoreFile.existsSync()) {
      return;
    }

    final repoPath = 'packages/${package.repositoryName}';
    final content = gitignoreFile.readAsStringSync();
    final lines = content.split('\n');
    
    // Remove a linha correspondente
    final filteredLines = lines.where((line) => line.trim() != repoPath).toList();
    
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
}