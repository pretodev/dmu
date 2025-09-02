import 'dart:io';

class ConsoleConfirm {
  /// Asks a yes/no question via terminal and returns true if user confirms
  /// with 'Y', 'y', 'yes', 'Yes', 'YES', etc.
  static bool ask(String question) {
    stdout.write('$question (Y/n): ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    return input.isEmpty || input == 'y' || input == 'yes';
  }

  /// Asks a yes/no question with custom options
  static bool askWithOptions(
    String question, {
    String yesOption = 'Y',
    String noOption = 'n',
  }) {
    stdout.write('$question ($yesOption/$noOption): ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    final yesLower = yesOption.toLowerCase();
    final yesFullWord = yesLower == 'y' ? 'yes' : yesLower;

    return input == yesLower || input == yesFullWord;
  }
}
