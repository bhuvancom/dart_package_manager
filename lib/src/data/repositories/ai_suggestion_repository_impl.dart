import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/repositories/ai_suggestion_repository.dart';

class AISuggestionRepositoryImpl implements AISuggestionRepository {
  @override
  Future<List<SuggestedPackage>> getSuggestions(String requirement, {String? apiKey, String? modelName, String? language}) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DPM_API_KEY environment variable is not set. AI features require an API key.');
    }

    final modelId = modelName ?? 'gemini-1.5-flash';
    final model = GenerativeModel(model: modelId, apiKey: apiKey);
    
    final targetLanguage = language ?? 'English';
    final prompt = '''
You are a Dart/Flutter expert. Given the following user requirement for a package, find the top 3 best-matched packages from pub.dev.
Provide the response as a valid JSON array of objects with keys: "name", "reasoning", "confidence" (0.0 to 1.0).

Requirement: "$requirement"
Target Language for "reasoning": "$targetLanguage"

JSON Response:
''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    
    final text = response.text;
    if (text == null) throw Exception('AI failed to generate a response.');

    // Extract JSON from potential markdown code blocks
    final jsonMatch = RegExp(r'\[.*\]', dotAll: true).stringMatch(text);
    if (jsonMatch == null) throw Exception('AI response did not contain a valid JSON array.');

    final List<dynamic> data = jsonDecode(jsonMatch);
    return data.map((item) => SuggestedPackage(
      name: item['name'] as String,
      reasoning: item['reasoning'] as String,
      confidence: (item['confidence'] as num).toDouble(),
    )).toList();
  }
}
