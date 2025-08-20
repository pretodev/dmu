import 'dart:io';

import 'package:process/process.dart';

import 'console_logger.dart';
import 'git_package.dart';

/// Gerencia operações Git (clone, remoção)
class GitManager {
  final ProcessManager _processManager;
  final String packagesDir;

  GitManager({required this.packagesDir, ProcessManager? processManager})
    : _processManager = processManager ?? const LocalProcessManager();

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

    ConsoleLogger.error('Falha ao clonar ${package.repositoryName}');
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

  /// Processa a seleção de pacotes (clona novos, remove desmarcados)
  Future<void> processSelection({
    required List<GitPackage> allPackages,
    required List<GitPackage> selectedPackages,
    required List<String> existingOverrides,
  }) async {
    final selectedNames = selectedPackages.map((p) => p.name).toSet();

    for (final packageName in existingOverrides) {
      if (!selectedNames.contains(packageName)) {
        final package = allPackages.firstWhere(
          (p) => p.name == packageName,
          orElse: () => throw StateError('Pacote $packageName não encontrado'),
        );
        await removeRepository(package);
      }
    }

    // Clona novos repositórios selecionados
    for (final package in selectedPackages) {
      if (!existingOverrides.contains(package.name)) {
        await cloneRepository(package);
      }
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
