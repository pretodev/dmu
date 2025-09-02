import 'dart:io';

import 'package:yaml/yaml.dart';

import 'console/console_logger.dart';

/// Classe responsável por verificar se um pacote está sendo usado no projeto
class PackageUsageChecker {
  final String projectRoot;

  PackageUsageChecker({required this.projectRoot});

  /// Verifica se um pacote está sendo usado no projeto
  ///
  /// Busca por imports do pacote em arquivos .dart e verifica se está
  /// nas dependencies ou dev_dependencies do pubspec.yaml
  bool isPackageInUse(String packageName) {
    try {
      // Verifica se está sendo importado em algum arquivo .dart
      if (_hasImportsInDartFiles(packageName)) {
        return true;
      }

      // Verifica se está nas dependencies ou dev_dependencies
      if (_isInPubspecDependencies(packageName)) {
        return true;
      }

      return false;
    } catch (e) {
      ConsoleLogger.error('Erro ao verificar uso do pacote $packageName: $e');
    }
  }

  /// Verifica se há imports do pacote em arquivos .dart
  bool _hasImportsInDartFiles(String packageName) {
    try {
      final dartFiles = _findDartFiles(Directory(projectRoot));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        // Busca por imports do tipo: import 'package:nome_do_pacote/...';
        final importRegex = RegExp('import\\s+[\'"]package:$packageName/');
        if (importRegex.hasMatch(content)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      ConsoleLogger.error('Erro ao buscar imports em arquivos .dart: $e');
    }
  }

  /// Verifica se o pacote está nas dependencies ou dev_dependencies
  bool _isInPubspecDependencies(String packageName) {
    try {
      final pubspecFile = File('$projectRoot/pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        ConsoleLogger.error('pubspec.yaml não encontrado');
      }

      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as Map<dynamic, dynamic>;

      // Verifica dependencies
      final dependencies = yaml['dependencies'] as Map<dynamic, dynamic>?;
      if (dependencies?.containsKey(packageName) == true) {
        return true;
      }

      // Verifica dev_dependencies
      final devDependencies =
          yaml['dev_dependencies'] as Map<dynamic, dynamic>?;
      if (devDependencies?.containsKey(packageName) == true) {
        return true;
      }

      return false;
    } catch (e) {
      ConsoleLogger.error('Erro ao verificar pubspec.yaml: $e');
    }
  }

  /// Encontra todos os arquivos .dart no projeto
  List<File> _findDartFiles(Directory directory) {
    final dartFiles = <File>[];

    try {
      final entities = directory.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Exclui alguns diretórios específicos
          final relativePath = entity.path.replaceFirst('$projectRoot/', '');
          if (!_shouldExcludeFile(relativePath)) {
            dartFiles.add(entity);
          }
        }
      }
    } catch (e) {
      ConsoleLogger.error('Erro ao buscar arquivos .dart: $e');
    }

    return dartFiles;
  }

  /// Verifica se um arquivo deve ser excluído da busca
  bool _shouldExcludeFile(String relativePath) {
    final excludedDirs = [
      'build/',
      '.dart_tool/',
      'package/',
      'packages/',
      '.git/',
    ];

    for (final dir in excludedDirs) {
      if (relativePath.startsWith(dir)) {
        return true;
      }
    }

    return false;
  }
}
