library dart_package_manager;

import 'src/ui.dart';

Future<void> run(List<String> arguments) async {
  final ui = CLIUI();
  await ui.start();
}
