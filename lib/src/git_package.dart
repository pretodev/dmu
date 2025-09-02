/// Representa um pacote Git com suas configurações
class GitPackage {
  final String name;
  final String url;
  final String ref;
  final String? path;

  const GitPackage({
    required this.name,
    required this.url,
    required this.ref,
    this.path,
  });

  /// Obtém o nome do repositório a partir da URL
  String get repositoryName {
    final uri = Uri.parse(url);
    return uri.pathSegments.last.replaceAll('.git', '');
  }

  /// Obtém o caminho local onde o repositório será clonado
  String getLocalPath(String packagesDir) {
    final basePath = '$packagesDir/$repositoryName';
    return path != null ? '$basePath/$path' : basePath;
  }

  /// Obtém o caminho relativo para uso no dependency_overrides
  String getRelativePath() {
    final basePath = 'packages/$repositoryName';
    return path != null ? '$basePath/$path' : basePath;
  }

  /// Converte URL HTTPS para SSH (específico para Azure DevOps)
  String get sshUrl {
    return url
        .replaceAll('https://dev.azure.com/', 'git@ssh.dev.azure.com:v3/')
        .replaceAll('/_git/', '/')
        .replaceAll('%20', ' ');
  }

  /// Formata o nome do pacote para exibição (capitaliza palavras)
  String get displayName {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  String toString() =>
      'GitPackage(name: $name, url: $url, ref: $ref, path: $path)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GitPackage &&
        other.name == name &&
        other.url == url &&
        other.ref == ref &&
        other.path == path;
  }

  @override
  int get hashCode => Object.hash(name, url, ref, path);
}
