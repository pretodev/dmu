import 'package:dmu/src/git/git_url_converter.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubUrlConverter', () {
    final converter = GitHubUrlConverter();

    test('canHandle returns true for GitHub URLs', () {
      expect(converter.canHandle('https://github.com/owner/repo.git'), true);
      expect(converter.canHandle('https://github.com/owner/repo'), true);
      expect(converter.canHandle('https://gitlab.com/owner/repo.git'), false);
    });

    test('toSsh converts HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://github.com/owner/repo.git'),
        'git@github.com:owner/repo.git',
      );
      expect(
        converter.toSsh('https://github.com/owner/repo'),
        'git@github.com:owner/repo',
      );
    });
  });

  group('GitLabUrlConverter', () {
    final converter = GitLabUrlConverter();

    test('canHandle returns true for GitLab URLs', () {
      expect(converter.canHandle('https://gitlab.com/owner/repo.git'), true);
      expect(
        converter.canHandle('https://gitlab.example.com/owner/repo.git'),
        true,
      );
      expect(converter.canHandle('https://github.com/owner/repo.git'), false);
    });

    test('toSsh converts HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://gitlab.com/owner/repo.git'),
        'git@gitlab.com:owner/repo.git',
      );
      expect(
        converter.toSsh('https://gitlab.example.com/owner/group/repo.git'),
        'git@gitlab.example.com:owner/group/repo.git',
      );
    });
  });

  group('BitbucketUrlConverter', () {
    final converter = BitbucketUrlConverter();

    test('canHandle returns true for Bitbucket URLs', () {
      expect(converter.canHandle('https://bitbucket.org/owner/repo.git'), true);
      expect(converter.canHandle('https://github.com/owner/repo.git'), false);
    });

    test('toSsh converts HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://bitbucket.org/owner/repo.git'),
        'git@bitbucket.org:owner/repo.git',
      );
    });
  });

  group('AzureDevOpsUrlConverter', () {
    final converter = AzureDevOpsUrlConverter();

    test('canHandle returns true for Azure DevOps URLs', () {
      expect(
        converter.canHandle('https://dev.azure.com/org/project/_git/repo'),
        true,
      );
      expect(
        converter.canHandle('https://org.visualstudio.com/project/_git/repo'),
        true,
      );
      expect(converter.canHandle('https://github.com/owner/repo.git'), false);
    });

    test('toSsh converts dev.azure.com HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://dev.azure.com/org/project/_git/repo'),
        'git@ssh.dev.azure.com:v3/org/project/repo',
      );
      expect(
        converter.toSsh('https://dev.azure.com/org/project%20name/_git/repo'),
        'git@ssh.dev.azure.com:v3/org/project name/repo',
      );
    });

    test('toSsh converts visualstudio.com HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://org.visualstudio.com/project/_git/repo'),
        'git@vs-ssh.visualstudio.com:v3/org/project/repo',
      );
    });
  });

  group('GiteaUrlConverter', () {
    final converter = GiteaUrlConverter();

    test('canHandle returns true for Gitea URLs', () {
      expect(
        converter.canHandle('https://gitea.example.com/owner/repo.git'),
        true,
      );
      expect(
        converter.canHandle('https://code.example.com/owner/repo.git'),
        false,
      );
    });

    test('toSsh converts HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://gitea.example.com/owner/repo.git'),
        'git@gitea.example.com:owner/repo.git',
      );
    });
  });

  group('GenericGitUrlConverter', () {
    final converter = GenericGitUrlConverter();

    test('canHandle always returns true', () {
      expect(converter.canHandle('https://any-host.com/owner/repo.git'), true);
    });

    test('toSsh converts HTTPS to SSH correctly', () {
      expect(
        converter.toSsh('https://custom-git.com/owner/repo.git'),
        'git@custom-git.com:owner/repo.git',
      );
    });
  });

  group('GitUrlConverterFactory', () {
    test('getConverter returns correct converter for GitHub', () {
      final converter = GitUrlConverterFactory.getConverter(
        'https://github.com/owner/repo.git',
      );
      expect(converter, isA<GitHubUrlConverter>());
    });

    test('getConverter returns correct converter for GitLab', () {
      final converter = GitUrlConverterFactory.getConverter(
        'https://gitlab.com/owner/repo.git',
      );
      expect(converter, isA<GitLabUrlConverter>());
    });

    test('getConverter returns correct converter for Bitbucket', () {
      final converter = GitUrlConverterFactory.getConverter(
        'https://bitbucket.org/owner/repo.git',
      );
      expect(converter, isA<BitbucketUrlConverter>());
    });

    test('getConverter returns correct converter for Azure DevOps', () {
      final converter = GitUrlConverterFactory.getConverter(
        'https://dev.azure.com/org/project/_git/repo',
      );
      expect(converter, isA<AzureDevOpsUrlConverter>());
    });

    test('getConverter returns GenericGitUrlConverter for unknown URLs', () {
      final converter = GitUrlConverterFactory.getConverter(
        'https://unknown-git-host.com/owner/repo.git',
      );
      expect(converter, isA<GenericGitUrlConverter>());
    });

    test('registerConverter allows custom converters', () {
      final customConverter = _CustomConverter();
      GitUrlConverterFactory.registerConverter(customConverter);

      final converter = GitUrlConverterFactory.getConverter(
        'https://custom.com/owner/repo.git',
      );
      expect(converter, isA<_CustomConverter>());
    });
  });
}

class _CustomConverter implements GitUrlConverter {
  @override
  bool canHandle(String url) => url.contains('custom.com');

  @override
  String toSsh(String url) => 'custom-ssh:$url';

  @override
  String getRepositoryName(String url) => 'custom-repo';
}
