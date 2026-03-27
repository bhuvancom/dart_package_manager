import 'dart:io';
import '../../domain/repositories/system_repository.dart';

class SystemRepositoryImpl implements SystemRepository {
  @override
  Future<void> runCommand(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw Exception('Failed to run $executable ${arguments.join(" ")}: ${result.stderr}');
    }
  }
}
