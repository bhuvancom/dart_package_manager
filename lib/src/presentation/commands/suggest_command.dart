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
  final String description =
      'Ask AI to find packages based on your requirements.';

  SuggestCommand() {
    argParser.addOption(
      'api-key',
      abbr: 'k',
      help: 'Google AI Studio API Key (overrides DPM_API_KEY env var).',
    );
    argParser.addOption(
      'lang',
      abbr: 'l',
      help: 'Language for AI reasoning (defaults to machine locale).',
    );
  }

  @override
  Future<void> run() async {
    final requirement = argResults?.rest.join(' ') ?? '';
    final modelName = argResults?['model'];
    final machineLocale =
        Platform.localeName.split('_')[0]; // e.g. "en" from "en_US"
    final language = argResults?['lang'] ?? machineLocale;
    final logger = Logger();

    if (requirement.isEmpty) {
      logger.err(
          'Please provide a requirement. Example: dpm suggest "I need to crop images"');
      return;
    }

    final apiKey =
        argResults?['api-key'] ?? Platform.environment['DPM_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.err('No API key provided.');
      logger.info('Please set DPM_API_KEY or use the --api-key flag:');
      logger.info(
          lightCyan.wrap('dpm suggest "requirement" --api-key="YOUR_KEY"')!);
      return;
    }

    final aiRepo = AISuggestionRepositoryImpl();
    final useCase = SuggestPackagesUseCase(repository: aiRepo);

    final spin = logger.progress(
        'AI ($modelName) is analyzing your requirement in $language...');

    try {
      final suggestions = await useCase.execute(requirement,
          apiKey: apiKey, modelName: modelName, language: language);
      spin.complete('AI has found matching packages! 🤖');

      if (suggestions.isEmpty) {
        logger.info(
            'AI couldn\'t find any specific matches. Try being more descriptive.');
        return;
      }

      for (var s in suggestions) {
        final confidenceColor =
            s.confidence > 0.8 ? green : (s.confidence > 0.5 ? yellow : red);
        logger.info(
            '\n📦 ${styleBold.wrap(s.name)} (Match: ${confidenceColor.wrap((s.confidence * 100).toInt().toString() + "%")})');
        logger.info(darkGray.wrap('   ${s.reasoning}')!);
      }

      final promptText = language == 'es'
          ? '¿Te gustaría instalar uno de estos?'
          : 'Would you like to install one of these?';
      logger.info('\n$promptText');

      final options = suggestions.map((s) => s.name).toList();
      final cancelText = language == 'es' ? '❌ Cancelar' : '❌ Cancel';
      options.add(red.wrap(cancelText)!);

      final selection = Select(
        prompt: language == 'es'
            ? 'Seleccionar para instalar'
            : 'Select to install',
        options: options,
      ).interact();

      if (selection == suggestions.length) {
        logger.info(language == 'es' ? 'Cancelado.' : 'Cancelled.');
        return;
      }

      final selectedPkg = suggestions[selection];
      final installingText = language == 'es'
          ? 'Instalando ${selectedPkg.name}...'
          : 'Installing ${selectedPkg.name}...';
      final installSpin = logger.progress(installingText);

      final pubspecRepo = PubspecRepositoryImpl();
      final systemRepo = SystemRepositoryImpl();
      final isFlutter = await pubspecRepo.isFlutterProject();
      final executable = isFlutter ? 'flutter' : 'dart';

      await systemRepo.runCommand(executable, ['pub', 'add', selectedPkg.name]);
      final successText = language == 'es'
          ? '${selectedPkg.name} instalado con éxito! 🎉'
          : '${selectedPkg.name} installed successfully! 🎉';
      installSpin.complete(successText);
    } catch (e) {
      spin.fail('AI Suggestion failed: ${e.toString()}');
    }
  }
}
