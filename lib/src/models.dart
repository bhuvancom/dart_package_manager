class PackageInfo {
  final String name;
  final String? currentVersion;
  final String? upgradableVersion;
  final String? resolvableVersion;
  final String? latestVersion;
  final bool isDiscontinued;
  final bool hasVulnerability;
  final String? advisoryUrl;

  PackageInfo({
    required this.name,
    this.currentVersion,
    this.upgradableVersion,
    this.resolvableVersion,
    this.latestVersion,
    this.isDiscontinued = false,
    this.hasVulnerability = false,
    this.advisoryUrl,
  });

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      name: json['package'] as String,
      currentVersion: json['current']?['version'] as String?,
      upgradableVersion: json['upgradable']?['version'] as String?,
      resolvableVersion: json['resolvable']?['version'] as String?,
      latestVersion: json['latest']?['version'] as String?,
      isDiscontinued: json['isDiscontinued'] == true,
      hasVulnerability: false, // We will map this later
      advisoryUrl: null,       // We will map this later
    );
  }

  bool get canUpdate => currentVersion != null && latestVersion != null && currentVersion != latestVersion;
}
