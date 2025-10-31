#!/usr/bin/env dart

import 'package:args/args.dart';
import 'package:dmu/dmu.dart';
import 'package:dmu/src/console/console_logger.dart';

/// dmu entry point
///
/// Manages Git dependencies as local packages in Dart/Flutter projects.
/// Allows cloning repositories locally and automatically configuring dependency_overrides
/// in pubspec.yaml.
void main(List<String> arguments) async {
  final parser =
      ArgParser()
        ..addCommand('add')
        ..addCommand('remove')
        ..addCommand('pub-get')
        ..addCommand('clean')
        ..addCommand('completions')
        ..addFlag(
          'help',
          abbr: 'h',
          help: 'Shows this help message',
          negatable: false,
        )
        ..addFlag(
          'version',
          abbr: 'v',
          help: 'Shows the version number',
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

  parser.commands['clean']!
    ..addFlag(
      'deep',
      abbr: 'd',
      help:
          'Recursively cleans dependencies of all dart packages within the project',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Shows help for the clean command',
      negatable: false,
    );

  parser.commands['completions']!.addFlag(
    'help',
    abbr: 'h',
    help: 'Shows help for the completions command',
    negatable: false,
  );

  try {
    final results = parser.parse(arguments);

    if (results['version'] as bool) {
      print('dmu version 1.0.0');
      return;
    }

    if (results['help'] as bool || arguments.isEmpty) {
      _showHelp(parser);
      return;
    }

    final dmu = DartMultiRepoUtility.forCurrentDirectory();
    final command = results.command;

    if (command == null) {
      ConsoleLogger.error(
        'No command specified.\n'
        'Run "dmu --help" to see available commands.',
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
            'Missing required argument: <package-name>\n'
            'Usage: dmu add <package-name> [options]\n'
            'Run "dmu add --help" for more information.',
          );
        }
        await dmu.add(command.rest.first);
        break;

      case 'remove':
        if (command['help'] as bool) {
          _showRemoveHelp();
          return;
        }

        if (command.rest.isEmpty) {
          ConsoleLogger.error(
            'Missing required argument: <package-name>\n'
            'Usage: dmu remove <package-name>\n'
            'Run "dmu remove --help" for more information.',
          );
        }
        final packageName = command.rest.first;
        await dmu.remove(packageName);
        break;

      case 'pub-get':
        if (command['help'] as bool) {
          _showGetHelp();
          return;
        }
        await dmu.pubGet();
        break;

      case 'clean':
        if (command['help'] as bool) {
          _showCleanHelp();
          return;
        }
        final deep = command['deep'] as bool;
        await dmu.clean(deep: deep);
        break;

      case 'completions':
        if (command['help'] as bool) {
          _showCompletionsHelp();
          return;
        }
        final packages = dmu.getAvailablePackages();
        for (final package in packages) {
          print(package);
        }
        break;

      default:
        ConsoleLogger.error(
          'Unknown command: "${command.name}"\n'
          'Run "dmu --help" to see available commands.',
        );
    }
  } catch (e) {
    if (e is FormatException) {
      ConsoleLogger.error(
        'Invalid arguments: ${e.message}\n'
        'Run "dmu --help" for usage information.',
      );
    } else {
      ConsoleLogger.error('Unexpected error: $e');
    }
  }
}

void _showHelp(ArgParser parser) {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU - Dart Multi-Repo Utility v1.0.0                          ║');
  print('║  Manage Git dependencies as local packages                     ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('USAGE:');
  print('  dmu <command> [arguments]');
  print('');
  print('COMMANDS:');
  print('  add <package>       Clone a Git dependency locally and override it');
  print(
    '  remove <package>    Remove local override and delete cloned package',
  );
  print(
    '  pub-get             Run pub get on all Dart/Flutter packages in project',
  );
  print('  clean               Clean build artifacts from all packages');
  print('  completions         List available packages for shell completion');
  print('');
  print('GLOBAL OPTIONS:');
  print('  -h, --help          Show this help message');
  print('  -v, --version       Show version number');
  print('');
  print('EXAMPLES:');
  print('  dmu add my_package              # Add package to local development');
  print(
    '  dmu remove my_package           # Remove package from local development',
  );
  print('  dmu pub-get                     # Download all dependencies');
  print(
    '  dmu clean --deep                # Deep clean with pubspec.lock removal',
  );
  print('');
  print('Run "dmu <command> --help" for more information about a command.');
}

void _showAddHelp() {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU ADD - Add Git dependency as local package                 ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('DESCRIPTION:');
  print('  Clone a Git-based dependency locally and configure it as a');
  print('  dependency_override in pubspec.yaml for local development.');
  print('');
  print('USAGE:');
  print('  dmu add <package-name> [options]');
  print('');
  print('ARGUMENTS:');
  print('  <package-name>      Name of the package to add (required)');
  print('                      Must be listed in dependencies with a Git URL');
  print('');
  print('OPTIONS:');
  print('  --path <directory>  Directory where package will be cloned');
  print('                      (default: packages)');
  print('  -h, --help          Show this help message');
  print('');
  print('REQUIREMENTS:');
  print('  • Package must be declared in pubspec.yaml dependencies');
  print('  • Dependency must use a Git repository URL');
  print('  • Git must be installed and available in PATH');
  print('');
  print('EXAMPLES:');
  print('  dmu add my_package');
  print('  dmu add my_package --path libs');
  print('');
  print('WHAT IT DOES:');
  print('  1. Verifies package exists in dependencies as Git repo');
  print('  2. Clones repository to specified path (default: packages/)');
  print('  3. Adds dependency_override to pubspec.yaml');
  print('  4. Runs flutter clean && flutter pub get');
  print('  5. Updates .gitignore to exclude packages directory');
}

void _showRemoveHelp() {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU REMOVE - Remove local package override                    ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('DESCRIPTION:');
  print('  Remove a package from dependency_overrides and delete its');
  print('  local cloned directory, reverting to the remote version.');
  print('');
  print('USAGE:');
  print('  dmu remove <package-name> [options]');
  print('');
  print('ARGUMENTS:');
  print('  <package-name>      Name of the package to remove (required)');
  print('');
  print('OPTIONS:');
  print('  -h, --help          Show this help message');
  print('');
  print('EXAMPLES:');
  print('  dmu remove my_package');
  print('');
  print('WHAT IT DOES:');
  print('  1. Verifies package is in dependency_overrides');
  print('  2. Removes override from pubspec.yaml');
  print('  3. Deletes local package directory');
  print('  4. Runs flutter clean && flutter pub get');
  print('');
  print('NOTE:');
  print('  Uncommitted changes in the local package will be lost!');
  print('  Make sure to commit or backup any changes before removing.');
}

void _showGetHelp() {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU PUB-GET - Download dependencies for all packages          ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('DESCRIPTION:');
  print('  Run pub get on all Dart/Flutter packages found in the project,');
  print('  including the root project and all local overrides.');
  print('');
  print('USAGE:');
  print('  dmu pub-get [options]');
  print('');
  print('OPTIONS:');
  print('  -h, --help          Show this help message');
  print('');
  print('REQUIREMENTS:');
  print('  • fd command-line tool must be installed');
  print(
    '    Install with: brew install fd (macOS) or apt install fd-find (Linux)',
  );
  print('');
  print('EXAMPLES:');
  print('  dmu pub-get');
  print('');
  print('WHAT IT DOES:');
  print('  1. Searches for all pubspec.yaml files in the project');
  print('  2. Runs flutter pub get (or dart pub get) on each package');
  print('  3. Uses fvm flutter if .fvmrc file is detected');
  print('  4. Reports success/failure for each package');
  print('');
  print('NOTE:');
  print('  This command automatically detects all Dart/Flutter packages');
  print('  in your workspace and ensures dependencies are up to date.');
}

void _showCleanHelp() {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU CLEAN - Clean build artifacts from packages               ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('DESCRIPTION:');
  print('  Clean build artifacts and caches from all Dart/Flutter packages');
  print('  in the project to resolve dependency or build issues.');
  print('');
  print('USAGE:');
  print('  dmu clean [options]');
  print('');
  print('OPTIONS:');
  print('  -d, --deep          Deep clean: also removes pubspec.lock files');
  print('  -h, --help          Show this help message');
  print('');
  print('REQUIREMENTS:');
  print('  • fd command-line tool must be installed');
  print(
    '    Install with: brew install fd (macOS) or apt install fd-find (Linux)',
  );
  print('');
  print('EXAMPLES:');
  print('  dmu clean              # Standard clean');
  print('  dmu clean --deep       # Deep clean with lock file removal');
  print('');
  print('WHAT IT DOES:');
  print('  Standard clean:');
  print('    • Runs flutter clean on all packages');
  print('    • Removes build/, .dart_tool/ directories');
  print('');
  print('  Deep clean (--deep):');
  print('    • Everything from standard clean');
  print('    • Also removes all pubspec.lock files');
  print('    • Forces complete dependency resolution on next pub get');
  print('');
  print('USE CASES:');
  print('  • Resolve mysterious build errors');
  print('  • Free up disk space');
  print('  • Reset dependency state (with --deep)');
  print('  • Prepare for fresh builds');
}

void _showCompletionsHelp() {
  print('╔════════════════════════════════════════════════════════════════╗');
  print('║  DMU COMPLETIONS - List available packages                     ║');
  print('╚════════════════════════════════════════════════════════════════╝');
  print('');
  print('DESCRIPTION:');
  print('  Lists all Git dependencies that can be added to the project.');
  print('  This command is primarily used by shell completion scripts.');
  print('');
  print('USAGE:');
  print('  dmu completions [options]');
  print('');
  print('OPTIONS:');
  print('  -h, --help          Show this help message');
  print('');
  print('OUTPUT:');
  print('  One package name per line, representing Git dependencies that');
  print(
    '  are defined in pubspec.yaml but not yet added to dependency_overrides.',
  );
  print('');
  print('EXAMPLES:');
  print('  dmu completions');
  print('');
  print('NOTE:');
  print(
    '  This command is used internally by shell completion scripts to provide',
  );
  print(
    '  tab-completion for the "dmu add" command. You typically don\'t need to',
  );
  print('  run this manually.');
}
