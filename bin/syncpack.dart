#!/usr/bin/env dart

import 'package:args/args.dart';
import 'package:syncpack/src/console/console_logger.dart';
import 'package:syncpack/syncpack.dart';

/// Syncpack entry point
///
/// Manages Git dependencies as local packages in Dart/Flutter projects.
/// Allows cloning repositories locally and automatically configuring dependency_overrides
/// in pubspec.yaml.
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('add')
    ..addCommand('remove')
    ..addCommand('pub-get')
    ..addCommand('clean')
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Shows this help message',
      negatable: false,
    );

  parser.commands['add']!
    ..addOption(
      'path',
      help:
          'Relative path where the package will be cloned (default: packages)',
      defaultsTo: 'packages',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Shows help for the add command',
      negatable: false,
    );

  parser.commands['remove']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Shows help for the remove command',
    negatable: false,
  );

  parser.commands['pub-get']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Shows help for the get command',
    negatable: false,
  );

  parser.commands['clean']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Shows help for the clean command',
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
        'Command not specified. Use --help to see available commands.',
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
            'Package name is required for the add command.',
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
            'Package name is required for the remove command.',
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
        ConsoleLogger.error('Unknown command: ${command.name}');
    }
  } catch (e) {
    if (e is FormatException) {
      ConsoleLogger.error('Argument error: ${e.message}');
    } else {
      ConsoleLogger.error('Fatal error: $e');
    }
  }
}

void _showHelp(ArgParser parser) {
  print(
    'Syncpack - Git dependency manager for Dart/Flutter projects\n',
  );
  print('Usage: syncpack <command> [options]\n');
  print('Available commands:');
  print(
    '  add <package-name>     Adds a package to dependency_override and clones locally',
  );
  print(
    '  remove <package-name>  Removes a package from dependency_override and local folder',
  );
  print('  update [package-name]  Updates one or all packages');
  print(
    '  pub-get              Runs flutter clean and pub get on all dependency_overrides',
  );
  print(
    '  clean                Cleans dependencies of all dart packages within the project',
  );
  print('\nGlobal options:');
  print(parser.usage);
  print(
    '\nUse "syncpack <command> --help" for more information about a specific command.',
  );
}

void _showAddHelp() {
  print('Adds a package to dependency_override and clones locally\n');
  print('Usage: syncpack add <package-name> [options]\n');
  print('Options:');
  print('  --path <path>     Relative path where to clone (default: package)');
  print('  -h, --help        Shows this help\n');
  print(
    'The package must be present in dependencies and be a Git repository.',
  );
}

void _showRemoveHelp() {
  print('Removes a package from dependency_override and local folder\n');
  print('Usage: syncpack remove <package-name> [options]\n');
  print('Options:');
  print('  -h, --help  Shows this help\n');
  print('Checks if the package is being used before removing.');
}

void _showGetHelp() {
  print('Runs flutter clean and pub get on all dependency_overrides\n');
  print('Usage: syncpack get [options]\n');
  print('Options:');
  print('  -h, --help  Shows this help\n');
  print('Downloads dependencies of all dart packages within the project');
}

void _showCleanHelp() {
  print('Completely cleans project dependencies\n');
  print('Usage: syncpack clean [options]\n');
  print('Options:');
  print('  -h, --help  Shows this help\n');
  print('Cleans dependencies of all dart packages within the project');
}
