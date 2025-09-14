/// Represents a Git package with its configurations
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

  /// Gets the repository name from the URL
  String get repositoryName {
    final uri = Uri.parse(url);
    return uri.pathSegments.last.replaceAll('.git', '');
  }

  /// Gets the local path where the repository will be cloned
  String getLocalPath(String packagesDir) {
    final basePath = '$packagesDir/$repositoryName';
    return path != null ? '$basePath/$path' : basePath;
  }

  /// Gets the relative path for use in dependency_overrides
  String getRelativePath() {
    final basePath = 'packages/$repositoryName';
    return path != null ? '$basePath/$path' : basePath;
  }

  /// Converts HTTPS URL to SSH (specific for Azure DevOps)
  String get sshUrl {
    return url
        .replaceAll('https://dev.azure.com/', 'git@ssh.dev.azure.com:v3/')
        .replaceAll('/_git/', '/')
        .replaceAll('%20', ' ');
  }

  /// Formats the package name for display (capitalizes words)
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
