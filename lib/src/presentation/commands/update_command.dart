import 'package:args/command_runner.dart';
import '../../ui.dart';

class UpdateCommand extends Command {
  @override
  final String name = 'update';
  
  @override
  final String description = 'Interactively check and update package dependencies.';

  UpdateCommand() {
    argParser.addFlag(
      'check',
      help: 'Check mode enabled. Run without --check to update.',
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final bool isVerbose = globalResults?['verbose'] == true;
    final bool isCheckOnly = argResults?['check'] == true;

    final ui = CLIUI(verbose: isVerbose, checkOnly: isCheckOnly);
    await ui.start();
  }
}
