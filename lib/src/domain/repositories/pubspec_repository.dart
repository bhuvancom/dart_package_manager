abstract class PubspecRepository {
  Future<Set<String>> getDependencies();
  Future<Set<String>> getDevDependencies();
  Future<bool> isFlutterProject();
}
