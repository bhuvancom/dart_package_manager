import 'package:test/test.dart';
import 'package:dart_package_manager/dart_package_manager.dart';

void main() {
  group('dart_package_manager', () {
    test('exports run function', () {
      expect(run, isA<Function>());
    });

    test('run function has correct signature', () {
      expect(run, isA<Future<void> Function(List<String>)>());
    });
  });
}
