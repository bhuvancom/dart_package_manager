import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import 'engine.dart';
import 'models.dart';

class CLIUI {
  final Logger _logger;
  late final Engine _engine;
  final bool checkOnly;

  CLIUI({bool verbose = false, this.checkOnly = false})
      : _logger = Logger(level: verbose ? Level.verbose : Level.info) {
    _engine = Engine(_logger);
  }

  Future<void> start() async {
    _logger.info(lightCyan.wrap('\n📦 Dart Package Manager')!);
    _logger
        .info('Analyzing dependencies and checking for vulnerabilities...\n');

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

    final updatable =
        packages.where((p) => p.canUpdate || p.hasVulnerability).toList();

    if (updatable.isEmpty) {
      _logger.success('All packages are up to date and secure ✨');
      return;
    }

    _logger
        .info('\n${styleBold.wrap('The following packages need attention:')}');

    // Print table
    final table = <List<String>>[
      ['Package', 'Current', 'Latest', 'Status', 'Vulnerability']
    ];

    for (var pkg in updatable) {
      String vulnStr = pkg.hasVulnerability
          ? red.wrap('⚠️ VULNERABLE')!
          : green.wrap('✅ Safe')!;
      String updateStr = pkg.canUpdate
          ? yellow.wrap('Update Available'.padRight(18))!
          : green.wrap('Up to Date      ')!;

      table.add([
        pkg.name,
        pkg.currentVersion ?? '-',
        pkg.latestVersion ?? '-',
        updateStr,
        vulnStr
      ]);
    }

    for (var row in table) {
      final isHeader = row[0] == 'Package';
      final nameStr = row[0].padRight(25);
      final currentStr = row[1].padRight(12);
      final latestStr = row[2].padRight(12);
      final updateStr = isHeader ? row[3].padRight(18) : row[3];
      final vulnStr = row[4];
      _logger
          .info('$nameStr | $currentStr | $latestStr | $updateStr | $vulnStr');
    }

    _logger.info('');

    final updateChoices = updatable.map((p) {
      if (p.hasVulnerability)
        return '${p.name} (Vulnerable: apply ${p.resolvableVersion ?? p.latestVersion})';
      return '${p.name} (Update: ${p.latestVersion})';
    }).toList();

    if (checkOnly) {
      _logger.info('Check mode enabled. Run without --check to update.');
      return;
    }

    _logger.info(
        'Select packages to update using Spacebar, then press Enter (Enter with 0 selections to skip):');

    final selections = MultiSelect(
      prompt: 'Packages to update',
      options: updateChoices,
      defaults: List.filled(updateChoices.length, false),
    ).interact();

    if (selections.isEmpty) {
      _logger.info('No packages selected for update. Exiting.');
      return;
    }

    final selectedPackages = selections.map((i) => updatable[i]).toList();

    final wantChangelogs = Confirm(
      prompt: 'View changelog links for selected packages?',
      defaultValue: false,
    ).interact();

    if (wantChangelogs) {
      _logger.info('\n${styleBold.wrap('Changelogs:')}');
      for (var pkg in selectedPackages) {
        _logger.info(
            '📦 ${pkg.name}: ${lightCyan.wrap('https://pub.dev/packages/${pkg.name}/changelog')}');
      }
      _logger.info('');

      final proceed = Confirm(
        prompt: 'Proceed with updates?',
        defaultValue: true,
      ).interact();

      if (!proceed) {
        _logger.info('Update cancelled.');
        return;
      }
    }

    for (var pkg in selectedPackages) {
      final targetVersion = pkg.resolvableVersion ?? pkg.latestVersion ?? '';
      if (targetVersion.isEmpty) continue;

      final updateSpin =
          _logger.progress('Updating ${pkg.name} to $targetVersion...');
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
