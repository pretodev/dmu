import 'dart:io';

import 'package:yaml/yaml.dart';

import '../console/console_logger.dart';
import '../git/git_package.dart';

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
          gitPackages.add(
            GitPackage(
              name: packageName,
              url: gitConfig,
              ref: 'main', // ref padrão
            ),
          );
        } else if (gitConfig is YamlMap) {
          // Formato completo: git: { url: ..., ref: ..., path: ... }
          final url = gitConfig['url'] as String?;
          final ref = gitConfig['ref'] as String? ?? 'main';
          final path = gitConfig['path'] as String?;

          if (url != null) {
            gitPackages.add(
              GitPackage(name: packageName, url: url, ref: ref, path: path),
            );
          }
        }
      }
    }

    return gitPackages;
  }

  /// Extrai os overrides existentes do pubspec.yaml
  List<String> parseExistingOverrides() {
    final overrides = <String>[];
    final dependencyOverrides =
        _yamlContent['dependency_overrides'] as YamlMap?;

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
  void updateDependencyOverrides(
    List<GitPackage> selectedPackages,
    String packagesDir,
  ) {
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
      final relativePath = package.getRelativePath();
      overrideLines.add('  ${package.name}:');
      overrideLines.add('    path: $relativePath');
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

  /// Limpa completamente todos os dependency_overrides do pubspec.yaml
  void clearAllDependencyOverrides() {
    _removeDependencyOverrides();
    _writePubspec();
    ConsoleLogger.info(
      'Todos os dependency_overrides foram removidos do pubspec.yaml',
    );
  }

  /// Verifica se um pacote específico existe nas dependencies e é Git
  GitPackage? findGitPackage(String packageName) {
    final gitPackages = parseGitDependencies();
    try {
      return gitPackages.firstWhere((pkg) => pkg.name == packageName);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona um único pacote ao dependency_overrides
  void addSingleDependencyOverride(GitPackage package, String packagesDir) {
    final existingOverrides = parseExistingOverrides();

    // Se já existe, não adiciona novamente
    if (existingOverrides.contains(package.name)) {
      ConsoleLogger.info(
        'Pacote ${package.name} já está em dependency_overrides',
      );
      return;
    }

    int? insertIndex = _findDependencyOverridesInsertIndex();
    if (insertIndex == null) {
      if (_lines.isNotEmpty && _lines.last.trim().isNotEmpty) {
        _lines.add('');
      }
      _lines.add('dependency_overrides:');
      insertIndex = _lines.length;
    }

    final relativePath = package.getRelativePath();
    _lines.insert(insertIndex, '  ${package.name}:');
    _lines.insert(insertIndex + 1, '    path: $relativePath');

    _writePubspec();
    ConsoleLogger.info('Adicionado ${package.name} ao dependency_overrides');
  }

  /// Remove um único pacote do dependency_overrides
  void removeSingleDependencyOverride(String packageName) {
    int? startIndex;
    int? endIndex;

    // Encontra o pacote específico no bloco dependency_overrides
    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i].trim();
      if (line == '$packageName:' && i > 0) {
        // Verifica se está dentro do bloco dependency_overrides
        bool inOverridesBlock = false;
        for (int j = i - 1; j >= 0; j--) {
          final prevLine = _lines[j].trim();
          if (prevLine == 'dependency_overrides:') {
            inOverridesBlock = true;
            break;
          } else if (prevLine.isNotEmpty &&
              !prevLine.startsWith('#') &&
              !_lines[j].startsWith(' ')) {
            break;
          }
        }

        if (inOverridesBlock) {
          startIndex = i;
          break;
        }
      }
    }

    if (startIndex == null) {
      ConsoleLogger.info(
        'Pacote $packageName não encontrado em dependency_overrides',
      );
      return;
    }

    // Encontra o fim da configuração do pacote
    for (int i = startIndex + 1; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.trim().isEmpty) continue;

      // Se não começa com espaços (próximo pacote ou nova seção)
      if (!line.startsWith('  ')) {
        endIndex = i;
        break;
      }

      // Se começa com 2 espaços mas não é indentação de propriedade (próximo pacote)
      if (line.startsWith('  ') &&
          !line.startsWith('    ') &&
          line.contains(':')) {
        endIndex = i;
        break;
      }
    }

    endIndex ??= _lines.length;

    // Remove as linhas do pacote
    _lines.removeRange(startIndex, endIndex);

    // Remove o bloco dependency_overrides se ficou vazio
    _removeEmptyDependencyOverridesBlock();

    _writePubspec();
    ConsoleLogger.info('Removido $packageName do dependency_overrides');
  }

  int? _findDependencyOverridesInsertIndex() {
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim().startsWith('dependency_overrides:')) {
        // Encontra o final do bloco para inserir
        for (int j = i + 1; j < _lines.length; j++) {
          final line = _lines[j];
          if (line.trim().isEmpty) continue;
          if (!line.startsWith(' ') && !line.startsWith('\t')) {
            return j;
          }
        }
        return _lines.length;
      }
    }
    return null;
  }

  void _removeEmptyDependencyOverridesBlock() {
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].trim() == 'dependency_overrides:') {
        // Verifica se o bloco está vazio (próxima linha não indentada ou fim do arquivo)
        bool isEmpty = true;
        for (int j = i + 1; j < _lines.length; j++) {
          final line = _lines[j];
          if (line.trim().isEmpty) continue;
          if (line.startsWith('  ') || line.startsWith('\t')) {
            isEmpty = false;
            break;
          } else {
            break;
          }
        }

        if (isEmpty) {
          _lines.removeAt(i);
          // Remove linha em branco anterior se existir
          if (i > 0 && _lines[i - 1].trim().isEmpty) {
            _lines.removeAt(i - 1);
          }
        }
        break;
      }
    }
  }
}
