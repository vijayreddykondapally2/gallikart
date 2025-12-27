# gallikart

Quick-commerce Flutter monorepo targeting Hyderabad outskirts.

## Getting Started

1. Install Flutter (3.9+ recommended) and run `flutter pub get`.
2. Supply your Firebase options (e.g., via `flutterfire configure`).
3. Run `flutter run` to launch the catalog-backed customer app.

### Branding + Launch Assets

- Place the provided logo at `assets/logo.png`. This file is already wired to the launcher (`flutter pub run flutter_launcher_icons`) and native splash (`flutter pub run flutter_native_splash:create`).
- To regenerate the icons or splash screen after swapping in a higher-res logo, rerun both commands above.

### Tooling

- Riverpod drives all feature controllers (`lib/features/...`).
- Firebase Core / Auth / Firestore are exposed through `lib/core/providers/core_providers.dart`.
- Feature routes are declared in `lib/routes/app_routes.dart` with a splash-to-catalog transition.
