import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:interact/interact.dart';
import '../../domain/use_cases/suggest_packages_use_case.dart';
import '../../data/repositories/ai_suggestion_repository_impl.dart';
import '../../data/repositories/system_repository_impl.dart';
import '../../data/repositories/pubspec_repository_impl.dart';

class SuggestCommand extends Command {
  @override
  final String name = 'suggest';

  @override
  final String description = 'Ask AI to find packages based on your requirements.';

  SuggestCommand() {
    argParser.addOption(
      'api-key',
      abbr: 'k',
      help: 'Google AI Studio API Key (overrides DPM_API_KEY env var).',
    );
    argParser.addOption(
      'model',
      abbr: 'm',
      help: 'Gemini model to use.',
      defaultsTo: 'gemini-1.5-flash',
    );
  }

  @override
  Future<void> run() async {
    final requirement = argResults?.rest.join(' ') ?? '';
    final modelName = argResults?['model'];
    final logger = Logger();

    if (requirement.isEmpty) {
      logger.err('Please provide a requirement. Example: dpm suggest "I need to crop images"');
      return;
    }

    final apiKey = argResults?['api-key'] ?? Platform.environment['DPM_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.err('No API key provided.');
      logger.info('Please set DPM_API_KEY or use the --api-key flag:');
      logger.info(lightCyan.wrap('dpm suggest "requirement" --api-key="YOUR_KEY"')!);
      return;
    }

    final aiRepo = AISuggestionRepositoryImpl();
    final useCase = SuggestPackagesUseCase(repository: aiRepo);

    final spin = logger.progress('AI ($modelName) is analyzing your requirement...');

    try {
      final suggestions = await useCase.execute(requirement, apiKey: apiKey, modelName: modelName);
      spin.complete('AI has found matching packages! 🤖');

      if (suggestions.isEmpty) {
        logger.info('AI couldn\'t find any specific matches. Try being more descriptive.');
        return;
      }

      for (var s in suggestions) {
        final confidenceColor = s.confidence > 0.8 ? green : (s.confidence > 0.5 ? yellow : red);
        logger.info('\n📦 ${styleBold.wrap(s.name)} (Match: ${confidenceColor.wrap((s.confidence * 100).toInt().toString() + "%")})');
        logger.info(darkGray.wrap('   ${s.reasoning}')!);
      }

      logger.info('\nWould you like to install one of these?');
      final options = suggestions.map((s) => s.name).toList();
      options.add(red.wrap('❌ Cancel')!);

      final selection = Select(
        prompt: 'Select to install',
        options: options,
      ).interact();

      if (selection == suggestions.length) {
        logger.info('Cancelled.');
        return;
      }

      final selectedPkg = suggestions[selection];
      final installSpin = logger.progress('Installing ${selectedPkg.name}...');
      
      final pubspecRepo = PubspecRepositoryImpl();
      final systemRepo = SystemRepositoryImpl();
      final isFlutter = await pubspecRepo.isFlutterProject();
      final executable = isFlutter ? 'flutter' : 'dart';
      
      await systemRepo.runCommand(executable, ['pub', 'add', selectedPkg.name]);
      installSpin.complete('${selectedPkg.name} installed successfully! 🎉');
      
    } catch (e) {
      spin.fail('AI Suggestion failed: ${e.toString()}');
    }
  }
}
