class SuggestedPackage {
  final String name;
  final String reasoning;
  final double confidence;

  SuggestedPackage({
    required this.name,
    required this.reasoning,
    required this.confidence,
  });
}

abstract class AISuggestionRepository {
  Future<List<SuggestedPackage>> getSuggestions(String requirement,
      {String? apiKey, String? modelName, String? language});
}
