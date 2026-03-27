import 'dart:io';
import '../../domain/repositories/file_system_repository.dart';

class FileSystemRepositoryImpl implements FileSystemRepository {
  @override
  Future<Set<String>> scanForUsedPackages(List<String> directoriesToScan) async {
    final usedPackages = <String>{};
    final importRegex = RegExp(r"(?:import|export)\s+['""]package:([a-zA-Z0-9_]+)/");

    for (final dirName in directoriesToScan) {
      final dir = Directory(dirName);
      if (await dir.exists()) {
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final fileContent = await entity.readAsString();
            final matches = importRegex.allMatches(fileContent);
            for (final match in matches) {
              if (match.groupCount >= 1) {
                usedPackages.add(match.group(1)!);
              }
            }
          }
        }
      }
    }

    final analysisFile = File('analysis_options.yaml');
    if (await analysisFile.exists()) {
      final analysisContent = await analysisFile.readAsString();
      final lintRegex = RegExp(r"include:\s+package:([a-zA-Z0-9_]+)/");
      final matches = lintRegex.allMatches(analysisContent);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          usedPackages.add(match.group(1)!);
        }
      }
    }
    return usedPackages;
  }

  @override
  Future<void> deletePaths(List<String> paths) async {
    for (final path in paths) {
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.directory) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } else if (type == FileSystemEntityType.file || type == FileSystemEntityType.link) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }
}
