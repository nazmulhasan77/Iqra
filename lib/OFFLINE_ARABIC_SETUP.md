# Offline Arabic Detection Setup

The `lib/` code now uses `whisper_ggml` + Whisper Tiny multilingual for local Arabic-vs-non-Arabic detection.

## 1. Add this dependency to the project's pubspec.yaml

```yaml
dependencies:
  whisper_ggml: ^2.6.0
```

Then run:

```bash
flutter pub get
```

`whisper_ggml` 2.6.0 requires Dart 3.7+ / Flutter 3.29+.

## 2. Best option: make first launch fully offline

Download the multilingual Whisper Tiny model named:

```text
ggml-tiny.bin
```

Put it here in the Flutter project:

```text
lib/assets/models/ggml-tiny.bin
```

Add this under the existing `flutter:` section of `pubspec.yaml`:

```yaml
flutter:
  assets:
    - lib/assets/models/ggml-tiny.bin
```

The app copies this bundled model to its local application-support directory and performs all recognition on-device.

## 3. If the model asset is not bundled

The code falls back to downloading Whisper Tiny once and caching it locally. This is only a model download; recorded audio is never uploaded for Arabic detection. After the model exists on the device, detection is offline.

## What changed

- Removed mock/random transcription.
- Removed Firebase upload and Firestore submission from the verification button.
- Records 16 kHz mono WAV.
- Runs Whisper Tiny locally with language=`auto`.
- Checks whether the resulting text is predominantly Arabic script.
- Returns only Arabic / Not Arabic for the app decision.

## Important limitation

This is a language gate, not Quran/Tajweed verification. Languages that also use Arabic-derived writing (for example Persian or Urdu) can occasionally look Arabic to the final script heuristic. For the intended Quran-recitation flow, it is designed mainly to reject clearly non-Arabic speech.
