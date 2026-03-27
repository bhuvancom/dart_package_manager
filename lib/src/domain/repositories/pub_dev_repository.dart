class PackageDetails {
  final String name;
  final String description;
  final String latestVersion;
  final int likes;

  PackageDetails({
    required this.name,
    required this.description,
    required this.latestVersion,
    required this.likes,
  });
}

abstract class PubDevRepository {
  Future<List<String>> searchPackages(String query, {int limit = 5});
  Future<PackageDetails?> getPackageDetails(String packageName);
}
