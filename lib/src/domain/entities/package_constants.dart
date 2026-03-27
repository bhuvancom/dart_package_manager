class PackageConstants {
  /// Packages that are often used by the build system or project configuration
  /// but are rarely imported directly in Dart code.
  static const Set<String> alwaysUsedPackages = {
    // Build Tools
    'build_runner',
    'json_serializable',
    'freezed',
    'freezed_annotation',
    'flutter_gen_runner',
    
    // Testing & Linting
    'test',
    'test_api',
    'lints',
    'flutter_lints',
    
    // Asset & Config Gen
    'flutter_launcher_icons',
    'flutter_native_splash',
    'change_app_package_name',
    
    // Flutter Essentials
    'flutter',
    'flutter_test',
    'sdk',
  };
}
