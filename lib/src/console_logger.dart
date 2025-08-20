import 'dart:io';

enum ConsoleColor { red, green, yellow, cyan, reset }

/// Gerencia output colorido no console
class ConsoleLogger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[0;31m';
  static const String _green = '\x1B[0;32m';
  static const String _yellow = '\x1B[0;33m';
  static const String _cyan = '\x1B[0;36m';
  static const String _bold = '\x1B[1m';

  /// Imprime uma mensagem de informação
  static void info(String message) {
    print('$_cyan$_bold==>$_reset$_bold $message$_reset');
  }

  /// Imprime uma mensagem de sucesso
  static void success(String message) {
    print('$_green$_bold==>$_reset$_bold $message$_reset');
  }

  /// Imprime uma mensagem de erro e sai do programa
  static Never error(String message) {
    stderr.writeln('$_red$_bold==> ERRO:$_reset$_red $message$_reset');
    exit(1);
  }

  /// Imprime texto com cor específica
  static void colored(String message, ConsoleColor color) {
    final colorCode = _getColorCode(color);
    print('$colorCode$message$_reset');
  }

  /// Retorna texto formatado com cor
  static String format(String text, ConsoleColor color, {bool bold = false}) {
    final colorCode = _getColorCode(color);
    final boldCode = bold ? _bold : '';
    return '$boldCode$colorCode$text$_reset';
  }

  static String _getColorCode(ConsoleColor color) {
    switch (color) {
      case ConsoleColor.red:
        return _red;
      case ConsoleColor.green:
        return _green;
      case ConsoleColor.yellow:
        return _yellow;
      case ConsoleColor.cyan:
        return _cyan;
      case ConsoleColor.reset:
        return _reset;
    }
  }
}
