import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/repositories/pub_dev_repository.dart';

class PubDevRepositoryImpl implements PubDevRepository {
  final http.Client _client = http.Client();

  @override
  Future<List<String>> searchPackages(String query, {int limit = 5}) async {
    final url = Uri.parse('https://pub.dev/api/search?q=${Uri.encodeComponent(query)}');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to search packages. Status: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final packagesList = data['packages'] as List<dynamic>? ?? [];
    
    return packagesList
        .take(limit)
        .map((p) => (p as Map<String, dynamic>)['package'] as String)
        .toList();
  }

  @override
  Future<PackageDetails?> getPackageDetails(String packageName) async {
    try {
      final infoUrl = Uri.parse('https://pub.dev/api/packages/$packageName');
      final metricsUrl = Uri.parse('https://pub.dev/api/packages/$packageName/metrics');

      final infoRes = await _client.get(infoUrl);
      final metricsRes = await _client.get(metricsUrl);

      if (infoRes.statusCode != 200) return null;

      final infoData = jsonDecode(infoRes.body) as Map<String, dynamic>;
      final latest = infoData['latest'] as Map<String, dynamic>;
      final pubspec = latest['pubspec'] as Map<String, dynamic>;
      final version = latest['version'] as String;
      final description = pubspec['description'] as String? ?? 'No description provided.';

      int likes = 0;
      if (metricsRes.statusCode == 200) {
        final metricsData = jsonDecode(metricsRes.body) as Map<String, dynamic>;
        final score = metricsData['score'] as Map<String, dynamic>?;
        if (score != null) {
          likes = score['likeCount'] as int? ?? 0;
        }
      }

      return PackageDetails(
        name: packageName,
        description: description.replaceAll(RegExp(r'\n|\r'), ' '),
        latestVersion: version,
        likes: likes,
      );
    } catch (_) {
      return null;
    }
  }
}
