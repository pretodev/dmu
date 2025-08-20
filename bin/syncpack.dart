#!/usr/bin/env dart

import 'package:syncpack/syncpack.dart';

/// Entry point do Syncpack
///
/// Gerencia dependências Git como pacotes locais em projetos Dart/Flutter.
/// Permite clonar repositórios localmente e configurar dependency_overrides
/// automaticamente no pubspec.yaml.
void main(List<String> arguments) async {
  try {
    final syncpack = Syncpack.forCurrentDirectory();
    await syncpack.run();
  } catch (e) {
    ConsoleLogger.error('Erro fatal: $e');
  }
}
