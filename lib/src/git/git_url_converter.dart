/// Base class for Git URL converters
abstract class GitUrlConverter {
  /// Checks if this converter can handle the given URL
  bool canHandle(String url);

  /// Converts HTTPS URL to SSH format
  String toSsh(String url);
}

/// Converter for GitHub URLs
class GitHubUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return url.contains('github.com');
  }

  @override
  String toSsh(String url) {
    // https://github.com/owner/repo.git -> git@github.com:owner/repo.git
    final uri = Uri.parse(url);
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return 'git@github.com:$path';
  }
}

/// Converter for GitLab URLs (both gitlab.com and self-hosted)
class GitLabUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return url.contains('gitlab');
  }

  @override
  String toSsh(String url) {
    // https://gitlab.com/owner/repo.git -> git@gitlab.com:owner/repo.git
    // https://gitlab.example.com/owner/repo.git -> git@gitlab.example.com:owner/repo.git
    final uri = Uri.parse(url);
    final host = uri.host;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return 'git@$host:$path';
  }
}

/// Converter for Bitbucket URLs
class BitbucketUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return url.contains('bitbucket.org');
  }

  @override
  String toSsh(String url) {
    // https://bitbucket.org/owner/repo.git -> git@bitbucket.org:owner/repo.git
    final uri = Uri.parse(url);
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return 'git@bitbucket.org:$path';
  }
}

/// Converter for Azure DevOps URLs
class AzureDevOpsUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return url.contains('dev.azure.com') || url.contains('visualstudio.com');
  }

  @override
  String toSsh(String url) {
    // https://dev.azure.com/org/project/_git/repo -> git@ssh.dev.azure.com:v3/org/project/repo
    if (url.contains('dev.azure.com')) {
      return url
          .replaceAll('https://dev.azure.com/', 'git@ssh.dev.azure.com:v3/')
          .replaceAll('/_git/', '/')
          .replaceAll('%20', ' ');
    }
    // https://org.visualstudio.com/project/_git/repo -> git@vs-ssh.visualstudio.com:v3/org/project/repo
    if (url.contains('visualstudio.com')) {
      final uri = Uri.parse(url);
      final org = uri.host.split('.').first;
      final path = uri.path
          .replaceAll('/_git/', '/')
          .substring(1); // Remove leading slash
      return 'git@vs-ssh.visualstudio.com:v3/$org/$path';
    }
    return url;
  }
}

/// Converter for Gitea URLs (self-hosted)
class GiteaUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return url.contains('gitea');
  }

  @override
  String toSsh(String url) {
    // https://gitea.example.com/owner/repo.git -> git@gitea.example.com:owner/repo.git
    final uri = Uri.parse(url);
    final host = uri.host;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return 'git@$host:$path';
  }
}

/// Factory class to get the appropriate URL converter
class GitUrlConverterFactory {
  static final List<GitUrlConverter> _converters = [
    GitHubUrlConverter(),
    GitLabUrlConverter(),
    BitbucketUrlConverter(),
    AzureDevOpsUrlConverter(),
    GiteaUrlConverter(),
  ];

  /// Gets the appropriate converter for the given URL
  static GitUrlConverter getConverter(String url) {
    for (final converter in _converters) {
      if (converter.canHandle(url)) {
        return converter;
      }
    }
    return GenericGitUrlConverter();
  }

  /// Registers a custom converter
  static void registerConverter(GitUrlConverter converter) {
    _converters.insert(0, converter);
  }
}

/// Generic converter for any Git URL
class GenericGitUrlConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) {
    return true;
  }

  @override
  String toSsh(String url) {
    // Generic conversion: https://host.com/path/repo.git -> git@host.com:path/repo.git
    final uri = Uri.parse(url);
    final host = uri.host;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return 'git@$host:$path';
  }
}
