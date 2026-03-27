import '../repositories/pubspec_repository.dart';
import '../repositories/file_system_repository.dart';
import '../entities/package_constants.dart';

class AnalyzeDependenciesUseCase {
  final PubspecRepository pubspecRepository;
  final FileSystemRepository fileSystemRepository;

  AnalyzeDependenciesUseCase({
    required this.pubspecRepository,
    required this.fileSystemRepository,
  });

  Future<AnalysisResult> execute({Set<String> manualIgnores = const {}}) async {
    final deps = await pubspecRepository.getDependencies();
    final devDeps = await pubspecRepository.getDevDependencies();
    
    final usedPackages = await fileSystemRepository.scanForUsedPackages(['lib', 'bin', 'test', 'example']);
    
    // Combine all packages that should be treated as "used"
    final allKnownUsed = {
      ...usedPackages,
      ...PackageConstants.alwaysUsedPackages,
      ...manualIgnores,
    };

    final unusedDeps = deps.where((p) => !allKnownUsed.contains(p)).toSet();
    final unusedDevDeps = devDeps.where((p) => !allKnownUsed.contains(p)).toSet();
    
    return AnalysisResult(
        unusedDependencies: unusedDeps, 
        unusedDevDependencies: unusedDevDeps,
        totalDependencies: deps.length,
        totalDevDependencies: devDeps.length
    );
  }
}

class AnalysisResult {
  final Set<String> unusedDependencies;
  final Set<String> unusedDevDependencies;
  final int totalDependencies;
  final int totalDevDependencies;

  AnalysisResult({
    required this.unusedDependencies, 
    required this.unusedDevDependencies, 
    required this.totalDependencies, 
    required this.totalDevDependencies
  });
}
