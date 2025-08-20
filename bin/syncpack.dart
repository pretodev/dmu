#!/usr/bin/env dart

import 'package:args/args.dart';
import 'package:syncpack/syncpack.dart';

/// Entry point do Syncpack
///
/// Gerencia dependências Git como pacotes locais em projetos Dart/Flutter.
/// Permite clonar repositórios localmente e configurar dependency_overrides
/// automaticamente no pubspec.yaml.
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'deep-clean',
      abbr: 'd',
      help: 'Limpa completamente tudo e faz do zero (remove packages/, dependency_overrides e .gitignore)',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Mostra esta mensagem de ajuda',
      negatable: false,
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Syncpack - Gerenciador de dependências Git para projetos Dart/Flutter\n');
      print('Uso: syncpack [opções]\n');
      print('Opções:');
      print(parser.usage);
      return;
    }

    final syncpack = Syncpack.forCurrentDirectory();
    final shouldDeepClean = results['deep-clean'] as bool;
    
    await syncpack.run(deepClean: shouldDeepClean);
  } catch (e) {
    if (e is FormatException) {
      ConsoleLogger.error('Erro nos argumentos: ${e.message}');
    } else {
      ConsoleLogger.error('Erro fatal: $e');
    }
  }
}
