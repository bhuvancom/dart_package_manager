import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dart_package_manager/src/domain/repositories/pubspec_repository.dart';
import 'package:dart_package_manager/src/domain/repositories/file_system_repository.dart';
import 'package:dart_package_manager/src/domain/use_cases/analyze_dependencies_use_case.dart';

class MockPubspecRepository extends Mock implements PubspecRepository {}

class MockFileSystemRepository extends Mock implements FileSystemRepository {}

void main() {
  late AnalyzeDependenciesUseCase useCase;
  late MockPubspecRepository mockPubspecRepo;
  late MockFileSystemRepository mockFileSystemRepo;

  setUp(() {
    mockPubspecRepo = MockPubspecRepository();
    mockFileSystemRepo = MockFileSystemRepository();
    useCase = AnalyzeDependenciesUseCase(
      pubspecRepository: mockPubspecRepo,
      fileSystemRepository: mockFileSystemRepo,
    );
  });

  group('AnalyzeDependenciesUseCase', () {
    test('should correctly identify unused dependencies', () async {
      // Arrange
      final deps = {'http', 'path', 'provider'};
      final devDeps = {'test', 'mocktail'};
      final used = {'http', 'test'}; // provider and path are unused

      when(() => mockPubspecRepo.getDependencies())
          .thenAnswer((_) async => deps);
      when(() => mockPubspecRepo.getDevDependencies())
          .thenAnswer((_) async => devDeps);
      when(() => mockFileSystemRepo.scanForUsedPackages(any()))
          .thenAnswer((_) async => used);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.unusedDependencies, contains('path'));
      expect(result.unusedDependencies, contains('provider'));
      expect(result.unusedDependencies, isNot(contains('http')));
      expect(result.unusedDevDependencies, contains('mocktail'));
      expect(result.unusedDevDependencies, isNot(contains('test')));
    });

    test('should respect manual ignores', () async {
      // Arrange
      final deps = {'provider'};
      final devDeps = <String>{};
      final used = <String>{}; // provider is unused

      when(() => mockPubspecRepo.getDependencies())
          .thenAnswer((_) async => deps);
      when(() => mockPubspecRepo.getDevDependencies())
          .thenAnswer((_) async => devDeps);
      when(() => mockFileSystemRepo.scanForUsedPackages(any()))
          .thenAnswer((_) async => used);

      // Act
      final result = await useCase.execute(manualIgnores: {'provider'});

      // Assert
      expect(result.unusedDependencies, isEmpty);
    });
  });
}
