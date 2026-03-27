import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'vulnerability_checker.dart';

class Engine {
  final VulnerabilityChecker _vulnChecker = VulnerabilityChecker();

  Future<List<PackageInfo>> getOutdatedPackages() async {
    // Determine if it's a flutter project by checking pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw Exception('No pubspec.yaml found in current directory.');
    }

    final content = await pubspecFile.readAsString();
    final isFlutter = content.contains('sdk: flutter') || content.contains('flutter:');
    
    final executable = isFlutter ? 'flutter' : 'dart';
    
    final result = await Process.run(executable, ['pub', 'outdated', '--format=json']);
    
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
      } else if (pkg.currentVersion != null) {
        // Fallback to OSV database query
        isVulnerable = await _vulnChecker.hasVulnerabilities(pkg.name, pkg.currentVersion!);
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
          advisoryUrl: advisoryUrl ?? 'https://osv.dev/packages/Pub/${pkg.name}', 
        );
      }
      return pkg;
    });

    return Future.wait(futures);
  }

  Future<void> updatePackage(String packageName, String version) async {
    final pubspecFile = File('pubspec.yaml');
    final content = await pubspecFile.readAsString();
    final isFlutter = content.contains('sdk: flutter') || content.contains('flutter:');
    
    final executable = isFlutter ? 'flutter' : 'dart';
    
    final result = await Process.run(executable, ['pub', 'add', '$packageName:^$version']);
    
    if (result.exitCode != 0) {
      throw Exception('Failed to update $packageName: ${result.stderr}');
    }
  }
}
