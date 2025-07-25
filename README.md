# Ludo Smart Mobile

A cross-platform Flutter application for hosting and joining online Ludo tournaments. The app integrates Firebase services and Razorpay payments while supporting Android, iOS, desktop, and web targets.

## Requirements

- **Flutter** stable channel (any 3.x release)
- **Dart** SDK 2.18 or later (<3.0)

Ensure Flutter is installed and added to your `PATH`. See the [Flutter installation guide](https://docs.flutter.dev/get-started/install) for details.

## Setup


1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Create a `.env` file using the provided example and update the backend URL (this file is ignored by Git):
   ```bash
   cp .env.example .env
   # Edit .env and set API_URL to your server address
   ```
   When using the Android emulator, set `API_URL` to `http://10.0.2.2:8000` so the emulator can reach your localhost.

## Running

Use Flutter's `--dart-define-from-file` option to load values from `.env` when launching the app.

### Android

```bash
flutter run -d android --dart-define-from-file=.env
```

### iOS

```bash
flutter run -d ios --dart-define-from-file=.env
```

### Web

```bash
flutter run -d chrome --dart-define-from-file=.env
```

Other desktop platforms can be run similarly by changing the device id (e.g. `windows`, `macos`, `linux`).

## Notes

Environment variables such as `API_URL` are compiled into the app at build time. Edit `.env` and re-run `flutter run` whenever these values change.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running Tests

Run the widget tests with:

```bash
flutter test
```

