import '../repositories/file_system_repository.dart';
import '../repositories/system_repository.dart';
import '../repositories/pubspec_repository.dart';

class CleanProjectUseCase {
  final FileSystemRepository fileSystemRepository;
  final SystemRepository systemRepository;
  final PubspecRepository pubspecRepository;

  CleanProjectUseCase({
    required this.fileSystemRepository,
    required this.systemRepository,
    required this.pubspecRepository,
  });

  Future<void> execute(void Function(String) onProgress) async {
    final dirsToDelete = [
      '.dart_tool', 
      'build', 
      'ios/Pods', 
      'macos/Pods', 
      'pubspec.lock', 
      'ios/Podfile.lock', 
      'macos/Podfile.lock'
    ];
    
    onProgress('Deleting cache directories and lockfiles...');
    await fileSystemRepository.deletePaths(dirsToDelete);
    
    final isFlutter = await pubspecRepository.isFlutterProject();
    final executable = isFlutter ? 'flutter' : 'dart';

    if (isFlutter) {
      onProgress('Running flutter clean...');
      try {
        await systemRepository.runCommand('flutter', ['clean']);
      } catch (e) {
        // flutter clean might fail gracefully if no build dir
      }
    }
    
    onProgress('Running $executable pub get...');
    await systemRepository.runCommand(executable, ['pub', 'get']);
  }
}
