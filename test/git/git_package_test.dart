import 'package:dmu/src/git/git_package.dart';
import 'package:test/test.dart';

void main() {
  group('GitPackage', () {
    group('with GitHub URL', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://github.com/owner/my-repo.git',
        ref: 'main',
      );

      test('repositoryName extracts correctly', () {
        expect(package.repositoryName, 'my-repo');
      });

      test('sshUrl converts correctly', () {
        expect(package.sshUrl, 'git@github.com:owner/my-repo.git');
      });

      test('getLocalPath returns correct path', () {
        expect(package.getLocalPath('packages'), 'packages/my-repo');
      });

      test('getRelativePath returns correct path', () {
        expect(package.getRelativePath(), 'packages/my-repo');
      });
    });

    group('with GitLab URL', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://gitlab.com/group/subgroup/my-repo.git',
        ref: 'develop',
      );

      test('repositoryName extracts correctly', () {
        expect(package.repositoryName, 'my-repo');
      });

      test('sshUrl converts correctly', () {
        expect(package.sshUrl, 'git@gitlab.com:group/subgroup/my-repo.git');
      });
    });

    group('with Bitbucket URL', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://bitbucket.org/team/my-repo.git',
        ref: 'master',
      );

      test('repositoryName extracts correctly', () {
        expect(package.repositoryName, 'my-repo');
      });

      test('sshUrl converts correctly', () {
        expect(package.sshUrl, 'git@bitbucket.org:team/my-repo.git');
      });
    });

    group('with Azure DevOps URL', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://dev.azure.com/org/project/_git/my-repo',
        ref: 'main',
      );

      test('repositoryName extracts correctly', () {
        expect(package.repositoryName, 'my-repo');
      });

      test('sshUrl converts correctly', () {
        expect(package.sshUrl, 'git@ssh.dev.azure.com:v3/org/project/my-repo');
      });
    });

    group('with path parameter', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://github.com/owner/monorepo.git',
        ref: 'main',
        path: 'packages/sub_package',
      );

      test('getLocalPath includes path', () {
        expect(
          package.getLocalPath('packages'),
          'packages/monorepo/packages/sub_package',
        );
      });

      test('getRelativePath includes path', () {
        expect(
          package.getRelativePath(),
          'packages/monorepo/packages/sub_package',
        );
      });
    });

    group('displayName formatting', () {
      test('capitalizes single word', () {
        final package = GitPackage(
          name: 'package',
          url: 'https://github.com/owner/repo.git',
          ref: 'main',
        );
        expect(package.displayName, 'Package');
      });

      test('capitalizes multiple words with underscores', () {
        final package = GitPackage(
          name: 'my_awesome_package',
          url: 'https://github.com/owner/repo.git',
          ref: 'main',
        );
        expect(package.displayName, 'My Awesome Package');
      });

      test('handles empty parts', () {
        final package = GitPackage(
          name: 'my__package',
          url: 'https://github.com/owner/repo.git',
          ref: 'main',
        );
        expect(package.displayName, 'My  Package');
      });
    });

    group('equality and hashCode', () {
      final package1 = GitPackage(
        name: 'package1',
        url: 'https://github.com/owner/repo.git',
        ref: 'main',
      );

      final package2 = GitPackage(
        name: 'package1',
        url: 'https://github.com/owner/repo.git',
        ref: 'main',
      );

      final package3 = GitPackage(
        name: 'package1',
        url: 'https://github.com/owner/repo.git',
        ref: 'develop',
      );

      test('equal packages are equal', () {
        expect(package1, equals(package2));
        expect(package1.hashCode, equals(package2.hashCode));
      });

      test('different packages are not equal', () {
        expect(package1, isNot(equals(package3)));
      });
    });

    test('toString returns correct format', () {
      final package = GitPackage(
        name: 'my_package',
        url: 'https://github.com/owner/repo.git',
        ref: 'main',
        path: 'packages/sub',
      );
      expect(
        package.toString(),
        'GitPackage(name: my_package, url: https://github.com/owner/repo.git, ref: main, path: packages/sub)',
      );
    });
  });
}
