import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'package:mason_logger/mason_logger.dart';
import 'vulnerability_checker.dart';

class Engine {
  final Logger logger;
  final VulnerabilityChecker _vulnChecker = VulnerabilityChecker();

  Engine(this.logger);

  Future<List<PackageInfo>> getOutdatedPackages() async {
    logger.detail('Reading pubspec.yaml to determine project type...');
    // Determine if it's a flutter project by checking pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw Exception('No pubspec.yaml found in current directory.');
    }

    final content = await pubspecFile.readAsString();
    final isFlutter =
        content.contains('sdk: flutter') || content.contains('flutter:');

    final executable = isFlutter ? 'flutter' : 'dart';

    logger.detail('Running command: $executable pub outdated --json');
    final result = await Process.run(executable, ['pub', 'outdated', '--json']);

    if (result.exitCode != 0) {
      throw Exception('Failed to run pub outdated: ${result.stderr}');
    }

    final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final packagesList = data['packages'] as List<dynamic>? ?? [];

    // Process packages asynchronously to check vulnerabilities
    final futures = packagesList.map((p) async {
      final pkg = PackageInfo.fromJson(p as Map<String, dynamic>);

      // Parse advisories if available in the dart SDK json output
      final advisories = p['advisories'] as List<dynamic>?;
      bool isVulnerable = false;
      String? advisoryUrl;

      if (advisories != null && advisories.isNotEmpty) {
        isVulnerable = true;
        advisoryUrl = 'https://pub.dev/packages/${pkg.name}/score';
        logger.detail('Found vulnerability config in pubspec for ${pkg.name}');
      } else if (pkg.currentVersion != null) {
        // Fallback to OSV database query
        logger.detail(
            'Checking OSV database for vulnerabilities in ${pkg.name} ${pkg.currentVersion}...');
        isVulnerable = await _vulnChecker.hasVulnerabilities(
            pkg.name, pkg.currentVersion!);
      }

      if (isVulnerable) {
        return PackageInfo(
          name: pkg.name,
          currentVersion: pkg.currentVersion,
          upgradableVersion: pkg.upgradableVersion,
          resolvableVersion: pkg.resolvableVersion,
          latestVersion: pkg.latestVersion,
          isDiscontinued: pkg.isDiscontinued,
          hasVulnerability: true,
          advisoryUrl:
              advisoryUrl ?? 'https://osv.dev/packages/Pub/${pkg.name}',
        );
      }
      return pkg;
    });

    return Future.wait(futures);
  }

  Future<void> updatePackage(String packageName, String version) async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final isFlutter =
        content.contains('sdk: flutter') || content.contains('flutter:');

    final executable = isFlutter ? 'flutter' : 'dart';

    logger
        .detail('Running command: $executable pub add $packageName:^$version');
    final result =
        await Process.run(executable, ['pub', 'add', '$packageName:^$version']);

    if (result.exitCode != 0) {
      throw Exception('Failed to update $packageName: ${result.stderr}');
    }
  }
}
