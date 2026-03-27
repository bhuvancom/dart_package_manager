import '../repositories/pub_dev_repository.dart';

class SearchPackagesUseCase {
  final PubDevRepository repository;

  SearchPackagesUseCase({required this.repository});

  Future<List<PackageDetails>> execute(String query) async {
    final packageNames = await repository.searchPackages(query);

    final detailsFutures =
        packageNames.map((name) => repository.getPackageDetails(name));
    final details = await Future.wait(detailsFutures);

    return details.whereType<PackageDetails>().toList();
  }
}
