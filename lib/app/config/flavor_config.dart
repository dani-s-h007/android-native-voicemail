enum Flavor {
  dev,
  staging,
  prod,
}

class FlavorConfig {
  final Flavor flavor;
  final String appTitle;
  final String applicationId;
  final bool enableDebugLogging;
  final bool mockServicesByDefault;

  const FlavorConfig({
    required this.flavor,
    required this.appTitle,
    required this.applicationId,
    required this.enableDebugLogging,
    required this.mockServicesByDefault,
  });

  static late final FlavorConfig instance;

  static void initialize({required FlavorConfig config}) {
    instance = config;
  }
}

