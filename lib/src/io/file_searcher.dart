import 'package:process/process.dart';

class FileSearcher {
  final String projectRoot;
  final ProcessManager _processManager;

  FileSearcher({
    required this.projectRoot,
    ProcessManager? processManager,
  }) : _processManager = processManager ?? const LocalProcessManager();

  Future<bool> isFdAvailable() async {
    try {
      final result = await _processManager.run(['fd', '--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> availablesDartProjects() async {
    final result = await _processManager.run([
      'fd',
      '-I',
      '-t',
      'f',
      'pubspec.yaml',
      '-E',
      '.dart_tool',
    ], workingDirectory: projectRoot);
    final projects = result.stdout.toString().split('\n');
    return projects
        .map((e) => e.replaceAll('pubspec.yaml', ''))
        .where((e) => e.isNotEmpty)
        .map((e) => '$projectRoot/$e')
        .toList();
  }
}
