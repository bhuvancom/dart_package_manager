library dart_package_manager;

import 'dart:io';
import 'package:args/command_runner.dart';
import 'src/presentation/commands/update_command.dart';
import 'src/presentation/commands/analyze_command.dart';
import 'src/presentation/commands/clean_command.dart';
import 'src/presentation/commands/add_command.dart';
import 'src/presentation/commands/suggest_command.dart';

Future<List<String>> _findWorkspaces(Directory dir) async {
  final List<String> paths = [];
  final entities = dir.listSync(recursive: true, followLinks: false);
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      final parent = entity.parent.path;
      if (!parent.contains('.dart_tool') &&
          !parent.contains('build') &&
          !parent.contains('.symlinks') &&
          !parent.contains('ios') &&
          !parent.contains('macos')) {
        paths.add(parent);
      }
    }
  }
  return paths;
}

Future<void> run(List<String> arguments) async {
  final runner = CommandRunner(
    'dpm',
    'A stunning visual dependencies manager for Dart and Flutter.',
  );

  runner.addCommand(UpdateCommand());
  runner.addCommand(AnalyzeCommand());
  runner.addCommand(CleanCommand());
  runner.addCommand(AddCommand());
  runner.addCommand(SuggestCommand());

  runner.argParser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Enable verbose logging.',
    negatable: false,
  );
  runner.argParser.addFlag(
    'recursive',
    abbr: 'r',
    help:
        'Run the command recursively on all Dart sub-projects in the workspace.',
    negatable: false,
  );

  try {
    final hasRecursive =
        arguments.contains('-r') || arguments.contains('--recursive');
    final processedArgs =
        arguments.where((a) => a != '-r' && a != '--recursive').toList();

    if (processedArgs.isEmpty ||
        processedArgs.contains('-h') ||
        processedArgs.contains('--help')) {
      runner.printUsage();
      return;
    }

    // If no command is provided but flags exist, default to 'update'
    List<String> argsToRun = processedArgs;
    if (processedArgs.isNotEmpty && processedArgs.first.startsWith('-')) {
      argsToRun = ['update', ...processedArgs];
    }

    if (hasRecursive) {
      final workspaces = await _findWorkspaces(Directory.current);
      if (workspaces.isEmpty) {
        print('No Dart projects found in the current directory tree.');
        return;
      }

      final originalDir = Directory.current.path;
      for (final workspace in workspaces) {
        Directory.current = workspace;
        print('\n\x1B[1m\x1B[36m🚀 Running in $workspace\x1B[0m\n');
        await runner.run(argsToRun);
      }
      Directory.current = originalDir;
    } else {
      await runner.run(argsToRun);
    }
  } on UsageException catch (e) {
    print(e.message);
    print(e.usage);
    exit(64);
  } catch (e) {
    print(e);
    exit(1);
  }
}
