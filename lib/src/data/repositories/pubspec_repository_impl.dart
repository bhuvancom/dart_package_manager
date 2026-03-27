import 'dart:io';
import '../../domain/repositories/pubspec_repository.dart';

class PubspecRepositoryImpl implements PubspecRepository {
  @override
  Future<Set<String>> getDependencies() async {
     return _parseDependencies(false);
  }

  @override
  Future<Set<String>> getDevDependencies() async {
     return _parseDependencies(true);
  }

  @override
  Future<bool> isFlutterProject() async {
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) return false;
    final content = await pubspecFile.readAsString();
    return content.contains('sdk: flutter') || content.contains('flutter:');
  }
  
  Future<Set<String>> _parseDependencies(bool isDev) async {
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw Exception('No pubspec.yaml found in the current directory.');
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');
    final result = <String>{};
    
    bool targetBlock = false;
    
    for (var line in lines) {
      if (line.trim().startsWith('#')) continue;
      
      if (line.startsWith(isDev ? 'dev_dependencies:' : 'dependencies:')) {
        targetBlock = true;
        continue;
      } else if (line.startsWith(isDev ? 'dependencies:' : 'dev_dependencies:')) {
        targetBlock = false;
        continue;
      } else if (!line.startsWith(' ') && line.trim().isNotEmpty && targetBlock) {
        targetBlock = false; // exited block
      }

      if (targetBlock && line.startsWith('  ') && !line.startsWith('    ')) {
        final parts = line.split(':');
        if (parts.isNotEmpty) {
          final pkgName = parts[0].trim();
          if (pkgName.isNotEmpty && pkgName != 'flutter' && pkgName != 'flutter_test' && pkgName != 'sdk') {
            result.add(pkgName);
          }
        }
      }
    }
    return result;
  }
}
