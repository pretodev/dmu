import 'package:process/process.dart';

class FileRemover {
  final String projectRoot;
  final ProcessManager _processManager;

  FileRemover({
    required this.projectRoot,
    ProcessManager? processManager,
  }) : _processManager = processManager ?? const LocalProcessManager();

  Future<bool> remove(List<String> paths) async {
    try {
      await _processManager.run(['rm', ...paths]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
