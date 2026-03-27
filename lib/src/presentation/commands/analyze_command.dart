import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../domain/use_cases/analyze_dependencies_use_case.dart';
import '../../data/repositories/pubspec_repository_impl.dart';
import '../../data/repositories/file_system_repository_impl.dart';

class AnalyzeCommand extends Command {
  @override
  final String name = 'analyze';

  @override
  final String description = 'Scan the project for unused dependencies.';

  AnalyzeCommand() {
    argParser.addOption(
      'ignore',
      abbr: 'i',
      help: 'Comma-separated list of packages to ignore during analysis.',
    );
  }

  @override
  Future<void> run() async {
    final logger = Logger();
    final ignoreList = argResults?['ignore']
            ?.toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        {};

    final pubspecRepo = PubspecRepositoryImpl();
    final fileSystemRepo = FileSystemRepositoryImpl();
    final useCase = AnalyzeDependenciesUseCase(
      pubspecRepository: pubspecRepo,
      fileSystemRepository: fileSystemRepo,
    );

    final scanSpin =
        logger.progress('Scanning Dart files and analyzing dependencies...');

    AnalysisResult result;
    try {
      result = await useCase.execute(manualIgnores: ignoreList);
      scanSpin.complete('Scan complete!');
    } catch (e) {
      scanSpin.fail('Failed to analyze repository: ${e.toString()}');
      return;
    }

    if (result.unusedDependencies.isEmpty &&
        result.unusedDevDependencies.isEmpty) {
      if (result.totalDependencies == 0 && result.totalDevDependencies == 0) {
        logger.info('No dependencies found to analyze.');
        return;
      }
      logger.success('✅ All your packages are actively used! Great job.');
      return;
    }

    logger.info(
        '\n${lightYellow.wrap('⚠️  The following packages might be unused:')}');

    if (result.unusedDependencies.isNotEmpty) {
      logger.info('\n${styleBold.wrap('Dependencies:')}');
      for (var pkg in result.unusedDependencies) {
        logger.info('  - $pkg');
      }
    }

    if (result.unusedDevDependencies.isNotEmpty) {
      logger.info('\n${styleBold.wrap('Dev Dependencies:')}');
      for (var pkg in result.unusedDevDependencies) {
        logger.info('  - $pkg');
      }
    }

    logger.info(
        '\n${darkGray.wrap('(Note: If a package provides a terminal executable, it might legally have no imports. Double check before removing!)')}');
  }
}
