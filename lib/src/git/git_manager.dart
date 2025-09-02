import 'dart:io';

import 'package:process/process.dart';

import '../console/console_logger.dart';
import 'git_package.dart';

/// Gerencia operações Git (clone, remoção)
class GitManager {
  final ProcessManager _processManager;
  final String packagesDir;

  GitManager({
    required this.packagesDir,
    ProcessManager? processManager,
  }) : _processManager = processManager ?? const LocalProcessManager();

  /// Clona um repositório Git
  Future<bool> cloneRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (repoDir.existsSync()) {
      ConsoleLogger.info(
        'Repositório ${package.repositoryName} já existe, pulando clone',
      );
      return true;
    }

    // Cria o diretório packages se não existir
    final packagesDirectory = Directory(packagesDir);
    if (!packagesDirectory.existsSync()) {
      packagesDirectory.createSync(recursive: true);
    }

    ConsoleLogger.info('Clonando ${package.repositoryName}...');

    // Tenta primeiro via SSH
    if (await _tryClone(package.sshUrl, package.ref, repoDir.path)) {
      ConsoleLogger.success('${package.repositoryName} clonado via SSH');
      return true;
    }

    ConsoleLogger.info('SSH falhou, tentando HTTPS...');

    // Tenta via HTTPS
    if (await _tryClone(package.url, package.ref, repoDir.path)) {
      ConsoleLogger.success('${package.repositoryName} clonado via HTTPS');
      return true;
    }

    return false;
  }

  /// Remove um repositório clonado
  Future<bool> removeRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (!repoDir.existsSync()) {
      return true; // Já removido
    }

    try {
      ConsoleLogger.info('Removendo ${package.repositoryName}...');
      repoDir.deleteSync(recursive: true);
      ConsoleLogger.success('${package.repositoryName} removido');
      return true;
    } catch (e) {
      ConsoleLogger.error('Falha ao remover ${package.repositoryName}: $e');
    }
  }

  /// Atualiza um repositório clonado (git pull)
  Future<bool> updateRepository(GitPackage package) async {
    final repoDir = Directory('$packagesDir/${package.repositoryName}');

    if (!repoDir.existsSync()) {
      ConsoleLogger.error('Repositório ${package.repositoryName} não existe');
    }

    try {
      ConsoleLogger.info('Atualizando ${package.repositoryName}...');

      // Executa git pull no diretório do repositório
      final result = await _processManager.run([
        'git',
        'pull',
      ], workingDirectory: repoDir.path);

      if (result.exitCode == 0) {
        ConsoleLogger.success('${package.repositoryName} atualizado');
        return true;
      }
      ConsoleLogger.error('Falha ao atualizar ${package.repositoryName}');
    } catch (e) {
      ConsoleLogger.error('Erro ao atualizar ${package.repositoryName}: $e');
    }
  }

  /// Clona um repositório em um caminho customizado
  Future<bool> cloneRepositoryToPath(
    GitPackage package,
    String customPath,
  ) async {
    final repoDir = Directory('$customPath/${package.repositoryName}');

    if (repoDir.existsSync()) {
      ConsoleLogger.info(
        'Repositório ${package.repositoryName} já existe em $customPath, pulando clone',
      );
      return true;
    }

    // Cria o diretório customizado se não existir
    final customDirectory = Directory(customPath);
    if (!customDirectory.existsSync()) {
      customDirectory.createSync(recursive: true);
    }

    ConsoleLogger.info('Clonando ${package.repositoryName} em $customPath...');

    // Tenta primeiro via SSH
    if (await _tryClone(package.sshUrl, package.ref, repoDir.path)) {
      ConsoleLogger.success(
        '${package.repositoryName} clonado via SSH em $customPath',
      );
      return true;
    }

    ConsoleLogger.info('SSH falhou, tentando HTTPS...');

    // Tenta via HTTPS
    if (await _tryClone(package.url, package.ref, repoDir.path)) {
      ConsoleLogger.success(
        '${package.repositoryName} clonado via HTTPS em $customPath',
      );
      return true;
    }

    ConsoleLogger.error(
      'Falha ao clonar ${package.repositoryName} em $customPath',
    );
  }

  /// Remove um repositório de um caminho customizado
  Future<bool> removeRepositoryFromPath(
    GitPackage package,
    String customPath,
  ) async {
    final repoDir = Directory('$customPath/${package.repositoryName}');

    if (!repoDir.existsSync()) {
      return true; // Já removido
    }

    try {
      ConsoleLogger.info(
        'Removendo ${package.repositoryName} de $customPath...',
      );
      repoDir.deleteSync(recursive: true);
      ConsoleLogger.success(
        '${package.repositoryName} removido de $customPath',
      );
      return true;
    } catch (e) {
      ConsoleLogger.error(
        'Falha ao remover ${package.repositoryName} de $customPath: $e',
      );
    }
  }

  Future<bool> _tryClone(String url, String ref, String targetPath) async {
    try {
      // Clone com branch/tag específica
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

  /// Verifica se o Git está disponível no sistema
  Future<bool> isGitAvailable() async {
    try {
      final result = await _processManager.run(['git', '--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Limpa o diretório packages se estiver vazio
  void cleanupPackagesDir() {
    final dir = Directory(packagesDir);
    if (dir.existsSync()) {
      final contents = dir.listSync();
      if (contents.isEmpty) {
        dir.deleteSync();
        ConsoleLogger.info('Diretório packages removido (estava vazio)');
      }
    }
  }
}
