import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../../domain/use_cases/clean_project_use_case.dart';
import '../../data/repositories/file_system_repository_impl.dart';
import '../../data/repositories/system_repository_impl.dart';
import '../../data/repositories/pubspec_repository_impl.dart';

class CleanCommand extends Command {
  @override
  final String name = 'clean';

  @override
  final String description =
      'Deep clean cache directories, lockfiles, and strictly reinstall dependencies.';

  @override
  Future<void> run() async {
    final logger = Logger();
    final fileSystemRepo = FileSystemRepositoryImpl();
    final systemRepo = SystemRepositoryImpl();
    final pubspecRepo = PubspecRepositoryImpl();

    final useCase = CleanProjectUseCase(
      fileSystemRepository: fileSystemRepo,
      systemRepository: systemRepo,
      pubspecRepository: pubspecRepo,
    );

    final spin = logger.progress('Starting deep clean...');

    try {
      await useCase.execute((progressMessage) {
        spin.update(progressMessage);
      });
      spin.complete(
          'Deep clean complete! Your project is fresh and ready to go. 🎉');
    } catch (e) {
      spin.fail('Deep clean failed: ${e.toString()}');
    }
  }
}
