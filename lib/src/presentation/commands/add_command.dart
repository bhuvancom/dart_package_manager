import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../domain/use_cases/search_packages_use_case.dart';
import '../../domain/repositories/pub_dev_repository.dart';
import '../../data/repositories/pub_dev_repository_impl.dart';
import '../../data/repositories/system_repository_impl.dart';
import '../../data/repositories/pubspec_repository_impl.dart';

class AddCommand extends Command {
  @override
  final String name = 'add';

  @override
  final String description = 'Interactively search pub.dev and install a package.';

  @override
  Future<void> run() async {
    final query = argResults?.rest.join(' ') ?? '';
    final logger = Logger();

    if (query.isEmpty) {
      logger.err('Please provide a search query. Example: dpm add state management');
      return;
    }

    final pubDevRepo = PubDevRepositoryImpl();
    final systemRepo = SystemRepositoryImpl();
    final pubspecRepo = PubspecRepositoryImpl();
    final useCase = SearchPackagesUseCase(repository: pubDevRepo);

    final spin = logger.progress('Searching pub.dev for "$query"...');
    
    List<PackageDetails> results;
    try {
      results = await useCase.execute(query);
      spin.complete('Search complete!');
    } catch (e) {
      spin.fail('Search failed: ${e.toString()}');
      return;
    }

    if (results.isEmpty) {
      logger.info('No packages found for "$query".');
      return;
    }

    final options = results.map((r) {
      final name = styleBold.wrap(r.name.padRight(20))!;
      final likes = lightCyan.wrap('👍 ${r.likes}')!.padRight(12);
      final desc = darkGray.wrap(r.description.length > 50 ? '${r.description.substring(0, 47)}...' : r.description)!;
      return '$name | $likes | $desc';
    }).toList();

    options.add(red.wrap('❌ Cancel')!);

    logger.info('Select a package to install:');
    final selection = Select(
      prompt: 'Packages',
      options: options,
    ).interact();

    if (selection == results.length) {
      logger.info('Installation cancelled.');
      return;
    }

    final selectedPackage = results[selection];
    
    final installSpin = logger.progress('Installing ${selectedPackage.name}...');
    try {
      final isFlutter = await pubspecRepo.isFlutterProject();
      final executable = isFlutter ? 'flutter' : 'dart';
      await systemRepo.runCommand(executable, ['pub', 'add', selectedPackage.name]);
      installSpin.complete('${selectedPackage.name} installed successfully! 🎉');
    } catch (e) {
      installSpin.fail('Failed to install ${selectedPackage.name}: ${e.toString()}');
    }
  }
}
