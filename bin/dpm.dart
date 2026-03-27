import 'package:dart_package_manager/dart_package_manager.dart' as dpm;

void main(List<String> arguments) async {
  print("Starting dart package manager.....");
  await dpm.run(arguments);
}
