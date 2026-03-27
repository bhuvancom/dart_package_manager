abstract class SystemRepository {
  Future<void> runCommand(String executable, List<String> arguments);
}
