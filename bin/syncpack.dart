#!/usr/bin/env dart

import 'package:args/args.dart';
import 'package:syncpack/src/console/console_logger.dart';
import 'package:syncpack/syncpack.dart';

/// Entry point do Syncpack
///
/// Gerencia dependências Git como pacotes locais em projetos Dart/Flutter.
/// Permite clonar repositórios localmente e configurar dependency_overrides
/// automaticamente no pubspec.yaml.
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('add')
    ..addCommand('remove')
    ..addCommand('pub-get')
    ..addCommand('clean')
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Mostra esta mensagem de ajuda',
      negatable: false,
    );

  // Configurar subcomando 'add'
  parser.commands['add']!
    ..addOption(
      'path',
      help: 'Caminho relativo onde o pacote será clonado (padrão: packages)',
      defaultsTo: 'packages',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Mostra ajuda para o comando add',
      negatable: false,
    );

  // Configurar subcomando 'remove'
  parser.commands['remove']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Mostra ajuda para o comando remove',
    negatable: false,
  );

  // Configurar subcomando 'get'
  parser.commands['pub-get']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Mostra ajuda para o comando get',
    negatable: false,
  );

  // Configurar subcomando 'clean'
  parser.commands['clean']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Mostra ajuda para o comando clean',
    negatable: false,
  );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || arguments.isEmpty) {
      _showHelp(parser);
      return;
    }

    final syncpack = Syncpack.forCurrentDirectory();
    final command = results.command;

    if (command == null) {
      ConsoleLogger.error(
        'Comando não especificado. Use --help para ver os comandos disponíveis.',
      );
    }

    switch (command.name) {
      case 'add':
        if (command['help'] as bool) {
          _showAddHelp();
          return;
        }
        if (command.rest.isEmpty) {
          ConsoleLogger.error(
            'Nome do pacote é obrigatório para o comando add.',
          );
        }
        await syncpack.add(command.rest.first);
        break;

      case 'remove':
        if (command['help'] as bool) {
          _showRemoveHelp();
          return;
        }
        if (command.rest.isEmpty) {
          ConsoleLogger.error(
            'Nome do pacote é obrigatório para o comando remove.',
          );
        }
        final packageName = command.rest.first;
        await syncpack.remove(packageName);
        break;

      case 'pub-get':
        if (command['help'] as bool) {
          _showGetHelp();
          return;
        }
        await syncpack.pubGet();
        break;

      case 'clean':
        if (command['help'] as bool) {
          _showCleanHelp();
          return;
        }
        await syncpack.clean();
        break;

      default:
        ConsoleLogger.error('Comando desconhecido: ${command.name}');
    }
  } catch (e) {
    if (e is FormatException) {
      ConsoleLogger.error('Erro nos argumentos: ${e.message}');
    } else {
      ConsoleLogger.error('Erro fatal: $e');
    }
  }
}

void _showHelp(ArgParser parser) {
  print(
    'Syncpack - Gerenciador de dependências Git para projetos Dart/Flutter\n',
  );
  print('Uso: syncpack <comando> [opções]\n');
  print('Comandos disponíveis:');
  print(
    '  add <package-name>     Adiciona um pacote ao dependency_override e clona localmente',
  );
  print(
    '  remove <package-name>  Remove um pacote do dependency_override e pasta local',
  );
  print('  update [package-name]  Atualiza um ou todos os pacotes');
  print(
    '  pub-get              Executa flutter clean e pub get em todos os dependency_overrides',
  );
  print(
    '  clean                Limpa as dependências de todos os pacotes dart dentro do projeto',
  );
  print('\nOpções globais:');
  print(parser.usage);
  print(
    '\nUse "syncpack <comando> --help" para mais informações sobre um comando específico.',
  );
}

void _showAddHelp() {
  print('Adiciona um pacote ao dependency_override e clona localmente\n');
  print('Uso: syncpack add <package-name> [opções]\n');
  print('Opções:');
  print('  --path <caminho>  Caminho relativo onde clonar (padrão: package)');
  print('  -h, --help        Mostra esta ajuda\n');
  print(
    'O pacote deve estar presente em dependencies e ser um repositório Git.',
  );
}

void _showRemoveHelp() {
  print('Remove um pacote do dependency_override e pasta local\n');
  print('Uso: syncpack remove <package-name> [opções]\n');
  print('Opções:');
  print('  -h, --help  Mostra esta ajuda\n');
  print('Verifica se o pacote está sendo usado antes de remover.');
}

void _showGetHelp() {
  print('Executa flutter clean e pub get em todos os dependency_overrides\n');
  print('Uso: syncpack get [opções]\n');
  print('Opções:');
  print('  -h, --help  Mostra esta ajuda\n');
  print('Baixa as dependências de todos o pacotes dart dentro do projeto');
}

void _showCleanHelp() {
  print('Limpa completamente as dependências do projeto\n');
  print('Uso: syncpack clean [opções]\n');
  print('Opções:');
  print('  -h, --help  Mostra esta ajuda\n');
  print('Limpa as dependências de todos os pacotes dart dentro do projeto');
}
