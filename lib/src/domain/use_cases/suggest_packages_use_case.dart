import '../repositories/ai_suggestion_repository.dart';

class SuggestPackagesUseCase {
  final AISuggestionRepository repository;

  SuggestPackagesUseCase({required this.repository});

  Future<List<SuggestedPackage>> execute(String requirement, {String? apiKey, String? modelName, String? language}) async {
    return await repository.getSuggestions(requirement, apiKey: apiKey, modelName: modelName, language: language);
  }
}
