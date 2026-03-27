import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import 'engine.dart';
import 'models.dart';

class CLIUI {
  final Engine _engine = Engine();
  final Logger _logger = Logger();

  Future<void> start() async {
    _logger.info(lightCyan.wrap('\n📦 Dart Package Manager')!);
    _logger.info('Analyzing dependencies and checking for vulnerabilities...\n');

    final spin = _logger.progress('Running pub outdated...');
    
    List<PackageInfo> packages;
    try {
      packages = await _engine.getOutdatedPackages();
      spin.complete('Analysis complete!');
    } catch (e) {
      spin.fail('Failed to analyze packages.');
      _logger.err(e.toString());
      return;
    }

    if (packages.isEmpty) {
      _logger.success('All packages are up to date and secure ✨');
      return;
    }

    final updatable = packages.where((p) => p.canUpdate || p.hasVulnerability).toList();
    
    if (updatable.isEmpty) {
      _logger.success('All packages are up to date and secure ✨');
      return;
    }

    _logger.info('\n${styleBold.wrap('The following packages need attention:')}');

    // Print table
    final table = <List<String>>[
      ['Package', 'Current', 'Latest', 'Status']
    ];

    for (var pkg in updatable) {
      String status = '';
      if (pkg.hasVulnerability) {
        status = red.wrap('⚠️ VULNERABLE')!;
      } else if (pkg.canUpdate) {
        status = yellow.wrap('Update Available')!;
      }
      
      table.add([
        pkg.name,
        pkg.currentVersion ?? '-',
        pkg.latestVersion ?? '-',
        status
      ]);
    }

    // Print poor man's simple table formatting
    for (var row in table) {
      final nameStr = row[0].padRight(25);
      final currentStr = row[1].padRight(12);
      final latestStr = row[2].padRight(12);
      final statusStr = row[3];
      _logger.info('$nameStr | $currentStr | $latestStr | $statusStr');
    }

    _logger.info('');

    final updateChoices = updatable.map((p) {
      if (p.hasVulnerability) return '${p.name} (Vulnerable: apply ${p.resolvableVersion ?? p.latestVersion})';
      return '${p.name} (Update: ${p.latestVersion})';
    }).toList();

    _logger.info('Select packages to update using Spacebar, then press Enter:');
    
    final selections = MultiSelect(
      prompt: 'Packages to update',
      options: updateChoices,
      defaults: List.filled(updateChoices.length, false),
    ).interact();

    if (selections.isEmpty) {
      _logger.info('No packages selected for update. Exiting.');
      return;
    }

    for (var index in selections) {
      final pkg = updatable[index];
      final targetVersion = pkg.resolvableVersion ?? pkg.latestVersion ?? '';
      if (targetVersion.isEmpty) continue;

      final updateSpin = _logger.progress('Updating ${pkg.name} to $targetVersion...');
      try {
        await _engine.updatePackage(pkg.name, targetVersion);
        updateSpin.complete('Updated ${pkg.name} successfully!');
      } catch (e) {
        updateSpin.fail('Failed to update ${pkg.name}');
        _logger.err(e.toString());
      }
    }
    
    _logger.success('\nAll selected packages updated successfully! 🎉');
  }
}
