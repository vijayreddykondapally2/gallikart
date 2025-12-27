// Context:
// This file is part of a quick commerce MVP for low-density areas.
// Keep logic simple, readable, and production-safe.
// Do not introduce unnecessary patterns or libraries.

class AppConfig {
  AppConfig._();

  static const int pageSize = 20;
  static const Duration requestTimeout = Duration(seconds: 10);
}
