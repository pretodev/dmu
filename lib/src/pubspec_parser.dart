import 'dart:io';
import 'package:yaml/yaml.dart';
import 'git_package.dart';
import 'console_logger.dart';

/// Parser para análise e manipulação do pubspec.yaml
class PubspecParser {
  final String pubspecPath;
  late final YamlMap _yamlContent;
  late final List<String> _lines;

  PubspecParser({required this.pubspecPath}) {
    _loadPubspec();
  }

  void _loadPubspec() {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      ConsoleLogger.error('pubspec.yaml não encontrado em: $pubspecPath');
    }

    final content = file.readAsStringSync();
    _lines = content.split('\n');
    _yamlContent = loadYaml(content) as YamlMap;
  }

  /// Extrai todos os pacotes Git das dependências
  List<GitPackage> parseGitDependencies() {
    final gitPackages = <GitPackage>[];
    final dependencies = _yamlContent['dependencies'] as YamlMap?;

    if (dependencies == null) return gitPackages;

    for (final entry in dependencies.entries) {
      final packageName = entry.key as String;
      final packageConfig = entry.value;

      if (packageConfig is YamlMap && packageConfig.containsKey('git')) {
        final gitConfig = packageConfig['git'];
        
        if (gitConfig is String) {
          // Formato simples: git: url
          gitPackages.add(GitPackage(
            name: packageName,
            url: gitConfig,
            ref: 'main', // ref padrão
          ));
        } else if (gitConfig is YamlMap) {
          // Formato completo: git: { url: ..., ref: ..., path: ... }
          final url = gitConfig['url'] as String?;
          final ref = gitConfig['ref'] as String? ?? 'main';
          final path = gitConfig['path'] as String?;

          if (url != null) {
            gitPackages.add(GitPackage(
              name: packageName,
              url: url,
              ref: ref,
              path: path,
            ));
          }
        }
      }
    }

    return gitPackages;
  }

  /// Extrai os overrides existentes do pubspec.yaml
  List<String> parseExistingOverrides() {
    final overrides = <String>[];
    final dependencyOverrides = _yamlContent['dependency_overrides'] as YamlMap?;

    if (dependencyOverrides == null) return overrides;

    for (final entry in dependencyOverrides.entries) {
      final packageName = entry.key as String;
      final packageConfig = entry.value;

      if (packageConfig is YamlMap && packageConfig.containsKey('path')) {
        overrides.add(packageName);
      }
    }

    return overrides;
  }

  /// Atualiza o pubspec.yaml com novos dependency_overrides
  void updateDependencyOverrides(List<GitPackage> selectedPackages, String packagesDir) {
    // Remove o bloco dependency_overrides existente
    _removeDependencyOverrides();

    if (selectedPackages.isEmpty) {
      _writePubspec();
      return;
    }

    // Adiciona novo bloco dependency_overrides
    _addDependencyOverrides(selectedPackages, packagesDir);
    _writePubspec();
  }

  void _removeDependencyOverrides() {
    int? startIndex;
    int? endIndex;

    // Encontra o início do bloco dependency_overrides
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim().startsWith('dependency_overrides:')) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == null) return;

    // Encontra o fim do bloco (próxima seção no mesmo nível ou fim do arquivo)
    for (int i = startIndex + 1; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.trim().isEmpty) continue;
      
      // Se a linha não começa com espaço, é uma nova seção
      if (!line.startsWith(' ') && !line.startsWith('\t')) {
        endIndex = i;
        break;
      }
    }

    endIndex ??= _lines.length;

    // Remove as linhas do bloco dependency_overrides
    _lines.removeRange(startIndex, endIndex);
  }

  void _addDependencyOverrides(List<GitPackage> packages, String packagesDir) {
    final overrideLines = <String>['dependency_overrides:'];
    
    for (final package in packages) {
      final localPath = package.getLocalPath(packagesDir);
      overrideLines.add('  ${package.name}:');
      overrideLines.add('    path: $localPath');
    }

    // Adiciona uma linha em branco antes se necessário
    if (_lines.isNotEmpty && _lines.last.trim().isNotEmpty) {
      _lines.add('');
    }

    _lines.addAll(overrideLines);
  }

  void _writePubspec() {
    final file = File(pubspecPath);
    file.writeAsStringSync(_lines.join('\n'));
  }
}