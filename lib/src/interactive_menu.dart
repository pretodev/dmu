import 'dart:io';
import 'git_package.dart';
import 'console_logger.dart';

/// Menu interativo para seleção de pacotes
class InteractiveMenu {
  final List<GitPackage> packages;
  final List<String> existingOverrides;
  late List<bool> _selected;
  int _currentIndex = 0;

  InteractiveMenu({
    required this.packages,
    required this.existingOverrides,
  }) {
    // Inicializa seleção baseada nos overrides existentes
    _selected = packages.map((pkg) => existingOverrides.contains(pkg.name)).toList();
  }

  /// Exibe o menu interativo e retorna os pacotes selecionados
  List<GitPackage> show() {
    if (packages.isEmpty) {
      ConsoleLogger.info('Nenhum pacote Git encontrado no pubspec.yaml');
      return [];
    }

    ConsoleLogger.info('Selecione os pacotes para clonar localmente:');
    print('');
    print('Use as setas ↑/↓ para navegar, ESPAÇO para selecionar/deselecionar, ENTER para confirmar');
    print('');

    _hideCursor();
    
    try {
      _renderMenu();
      _handleInput();
    } finally {
      _showCursor();
    }

    final selectedPackages = <GitPackage>[];
    for (int i = 0; i < packages.length; i++) {
      if (_selected[i]) {
        selectedPackages.add(packages[i]);
      }
    }

    return selectedPackages;
  }

  void _renderMenu() {
    // Move cursor para o início do menu
    stdout.write('\x1B[${packages.length + 1}A');
    
    for (int i = 0; i < packages.length; i++) {
      final package = packages[i];
      final isSelected = _selected[i];
      final isCurrent = i == _currentIndex;
      
      // Limpa a linha
      stdout.write('\x1B[2K');
      
      if (isCurrent) {
        // Item atual (destacado)
        final checkbox = isSelected ? '☑' : '☐';
        final arrow = ConsoleLogger.format('>', ConsoleColor.cyan, bold: true);
        final name = ConsoleLogger.format(package.displayName, ConsoleColor.yellow, bold: true);
        print('$arrow $checkbox $name');
      } else {
        // Item normal
        final checkbox = isSelected ? '☑' : '☐';
        print('  $checkbox ${package.displayName}');
      }
    }
  }

  void _handleInput() {
    stdin.echoMode = false;
    stdin.lineMode = false;

    while (true) {
      final input = stdin.readByteSync();
      
      switch (input) {
        case 27: // ESC sequence
          final next1 = stdin.readByteSync();
          final next2 = stdin.readByteSync();
          
          if (next1 == 91) { // '['
            switch (next2) {
              case 65: // Seta para cima
                _moveUp();
                break;
              case 66: // Seta para baixo
                _moveDown();
                break;
            }
          }
          break;
          
        case 32: // Espaço
          _toggleSelection();
          break;
          
        case 10: // Enter
        case 13: // Carriage return
          stdin.echoMode = true;
          stdin.lineMode = true;
          return;
          
        case 3: // Ctrl+C
          stdin.echoMode = true;
          stdin.lineMode = true;
          exit(0);
      }
      
      _renderMenu();
    }
  }

  void _moveUp() {
    if (_currentIndex > 0) {
      _currentIndex--;
    }
  }

  void _moveDown() {
    if (_currentIndex < packages.length - 1) {
      _currentIndex++;
    }
  }

  void _toggleSelection() {
    _selected[_currentIndex] = !_selected[_currentIndex];
  }

  void _hideCursor() {
    stdout.write('\x1B[?25l');
  }

  void _showCursor() {
    stdout.write('\x1B[?25h');
  }
}