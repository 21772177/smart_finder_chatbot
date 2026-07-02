# Second Brain

A privacy-first Android AI assistant that uses a floating overlay to analyze any screen content on-demand. All processing is local — your data never leaves your device.

## Features

- **Floating overlay** — tap to analyze any screen
- **AI-powered understanding** — OCR, summarization, translation
- **Local-first** — everything stored on-device with encryption
- **Semantic search** — find saved memories by meaning, not just keywords
- **Privacy by design** — no continuous monitoring, no cloud storage by default

## Tech Stack

- **Flutter** + Riverpod + Material 3
- **Android**: AccessibilityService, MediaProjection, Foreground Service
- **AI**: ML Kit OCR, Whisper (optional), local LLM embeddings
- **Storage**: Drift (SQLite) with encrypted local database
- **DevOps**: GitHub Actions

## Build

```bash
flutter pub get
dart run build_runner build
flutter build apk --debug
```
