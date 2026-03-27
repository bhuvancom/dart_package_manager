abstract class FileSystemRepository {
  Future<Set<String>> scanForUsedPackages(List<String> directoriesToScan);
  Future<void> deletePaths(List<String> paths);
}
