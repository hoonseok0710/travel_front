# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Lint / static analysis
flutter analyze

# Build
flutter build apk          # Android
flutter build ios          # iOS
```

## Architecture

This is a Flutter travel-record app ("여행 기록") for logging visits to Korean regions. It targets Android and iOS.

**State management:** Riverpod (`flutter_riverpod`). All providers live in `lib/features/<feature>/provider/`.

**Routing:** `go_router` with a redirect guard. The guard reads `isLoggedInProvider` (a `FutureProvider`) on every navigation and redirects to `/login` when unauthenticated. Route definitions are in `lib/core/config/router.dart`.

**HTTP:** Dio (`lib/core/network/dio_client.dart`). A single `DioClient.getInstance()` factory creates a Dio instance configured with `AppConfig.baseUrl` and attaches `_AuthInterceptor`, which:
- Injects `Authorization: Bearer <token>` from `TokenStorage` on every request.
- On 401, attempts token refresh via `POST /auth/reissue`, saves new tokens, and retries the original request.
- On refresh failure, clears tokens (triggering a redirect to login on next navigation).

The Dio instance is exposed via `dioProvider` (`lib/core/network/dio_provider.dart`) and consumed by all repositories.

**Token persistence:** `flutter_secure_storage` wrapped in `TokenStorage` (`lib/core/storage/token_storage.dart`).

**Backend base URL:** `https://travel-production-3ff0.up.railway.app/api/v1` (defined in `lib/core/config/app_config.dart`).

### Feature layout

Each feature follows the same internal structure:

```
lib/features/<feature>/
  model/          # Plain Dart data classes with fromJson
  repository/     # Dio-based API calls, takes Dio in constructor
  provider/       # Riverpod providers (Provider for repos, FutureProvider for data)
  screen/         # Stateful/Stateless/Consumer widgets
```

Features: `auth`, `map`, `pin`, `photo`.

### SVG Korea map

`assets/maps/korea.svg` is parsed **once at startup** by `SvgRegionCache.initialize()` (called in `main()`). It converts each SVG `<path>` element into a Flutter `Path` and stores it keyed by the element's `id` attribute (e.g. `"seoul"`, `"busan"`).

`KoreaMapWidget` (`lib/features/map/screen/korea_map_widget.dart`) uses a `CustomPainter` to draw the regions. Visited regions are highlighted blue; unvisited regions are grey. Tapping the map converts screen coordinates back to SVG coordinates to detect which region was tapped.

Photos are rendered as overlays clipped to their region's SVG path via `_PathClipper`. The clip uses a 4×4 matrix transform to map SVG space → screen space.

### Photo transform

Each `PinRecord` stores `photoOffsetX`, `photoOffsetY`, `photoScale`. These are **normalized** relative to the on-screen region size (not absolute pixels). When saving from `_PhotoTransformEditor`, the raw pixel offsets are divided by the displayed region dimensions to produce normalized values; when rendering in `KoreaMapWidget`, the normalized values are multiplied back by `screenWidth`/`screenHeight`.

### Riverpod cache invalidation pattern

After mutations (create/update/delete), providers are invalidated with `ref.invalidate(someProvider)` so the next read re-fetches from the server. There is no local optimistic update layer.
