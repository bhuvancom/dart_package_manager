import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dart_package_manager/src/domain/repositories/ai_suggestion_repository.dart';
import 'package:dart_package_manager/src/domain/use_cases/suggest_packages_use_case.dart';

class MockAISuggestionRepository extends Mock
    implements AISuggestionRepository {}

void main() {
  late SuggestPackagesUseCase useCase;
  late MockAISuggestionRepository mockRepository;

  setUp(() {
    mockRepository = MockAISuggestionRepository();
    useCase = SuggestPackagesUseCase(repository: mockRepository);
  });

  group('SuggestPackagesUseCase', () {
    test('should return suggestions when repository succeeds', () async {
      // Arrange
      final requirement = 'I need to crop images';
      final apiKey = 'test_key';
      final expectedSuggestions = [
        SuggestedPackage(
            name: 'image_cropper',
            reasoning: 'Best for cropping',
            confidence: 0.95),
      ];

      when(() => mockRepository.getSuggestions(requirement,
              apiKey: apiKey, modelName: any(named: 'modelName')))
          .thenAnswer((_) async => expectedSuggestions);

      // Act
      final result = await useCase.execute(requirement, apiKey: apiKey);

      // Assert
      expect(result, equals(expectedSuggestions));
      verify(() => mockRepository.getSuggestions(requirement,
          apiKey: apiKey, modelName: any(named: 'modelName'))).called(1);
    });

    test('should propagate error when repository fails', () async {
      // Arrange
      final requirement = 'bad requirement';
      when(() => mockRepository.getSuggestions(any(),
              apiKey: any(named: 'apiKey'), modelName: any(named: 'modelName')))
          .thenThrow(Exception('API Error'));

      // Act & Assert
      expect(() => useCase.execute(requirement), throwsA(isA<Exception>()));
    });
  });
}
