# Second Brain

A privacy-first Android AI assistant that uses a floating overlay to analyze any screen content on-demand. All processing is local — your data never leaves your device unless you explicitly opt into cloud LLM.

## Features

- **Floating overlay** — tap to analyze any screen content
- **AI-powered understanding** — OCR extraction, summarization, translation, explanation, key takeaways
- **Local-first storage** — encrypted SQLite database with SQLCipher
- **Semantic search** — word-level TF-IDF embeddings for meaning-based memory retrieval
- **Cloud LLM (opt-in)** — Gemini, OpenAI GPT, Anthropic Claude integration
- **Audio transcription** — on-device speech-to-text for audio/video content
- **Google Drive backup** — encrypted database backup to Google Drive
- **Dark mode** — system/light/dark theme support
- **Banking app protection** — blocks overlay on banking, password, and payment apps
- **Data export** — share your memories as JSON via system share sheet
- **Configurable retention** — set how long cache files are kept (default: 30 days)

## Privacy

- No continuous monitoring — only captures when you tap
- No cloud storage by default — everything stays on your device
- API keys encrypted at rest using AES-GCM
- Database encrypted with SQLCipher
- Banking, password, and payment apps are blocked by default
- You can export or delete your data anytime

## Tech Stack

- **Framework**: Flutter 3.11+ with Dart
- **State Management**: Riverpod
- **Database**: Drift (SQLite) + SQLCipher for encryption
- **Android Native**: Kotlin (AccessibilityService, MediaProjection, Foreground Service, WorkManager)
- **AI/ML**: Google ML Kit OCR, word-level TF-IDF embeddings, cosine similarity search
- **Cloud (opt-in)**: Google Generative AI, OpenAI API, Anthropic API
- **Backup**: Google Drive API via googleapis
- **CI/CD**: GitHub Actions

## Architecture

```
lib/
├── core/                    # Constants, theme, logger
├── features/
│   ├── analyze/             # Cloud & local LLM analysis services
│   ├── audio/               # Audio transcription service
│   ├── backup/              # Google Drive encrypted backup
│   ├── capture/             # Screen capture, OCR, capture state
│   ├── chat/                # Search and recent memories UI
│   ├── memory/              # Database, repository, models, embeddings
│   ├── onboarding/          # Permission onboarding flow
│   ├── overlay/             # Floating overlay service & UI
│   ├── permissions/         # Permission dashboard
│   ├── security/            # Keystore, encrypted preferences
│   └── settings/            # Settings service & UI
android/app/src/main/kotlin/
├── overlay/                 # AccessibilityService, overlay bubble, result overlay
├── service/                 # Foreground service, cleanup worker
├── audio/                   # Audio transcription handler
├── llm/                     # Local LLM JNI handler (stub)
└── security/                # Android Keystore integration
```

## Setup

### Prerequisites

- Flutter SDK 3.11+
- Android SDK 26+ (minSdk)
- Java 17

### Quick Start

```bash
# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run in debug mode
flutter run
```

### Firebase Setup (Optional — for Crashlytics)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add your Android app with package name `com.secondbrain.second_brain`
3. Download `google-services.json` and place it in `android/app/`
4. Run:
   ```bash
   flutterfire configure
   ```
5. The app will gracefully degrade without Firebase — Crashlytics simply won't report.

### Release Signing

The app uses environment variables for release signing. Set these before building:

```bash
export KEYSTORE_PATH=path/to/your/release.keystore
export KEY_ALIAS=your-key-alias
export KEYSTORE_PASSWORD=your-keystore-password
export KEY_PASSWORD=your-key-password
```

If these are not set, the release build falls back to debug signing keys.

### Cloud LLM Setup (Optional)

1. Go to Settings > AI Features > Cloud LLM
2. Toggle "Cloud LLM (Opt-in)" on
3. Select your provider (Gemini, OpenAI, or Anthropic)
4. Enter your API key:
   - **Gemini**: Get a key at [ai.google.dev](https://ai.google.dev)
   - **OpenAI**: Get a key at [platform.openai.com](https://platform.openai.com)
   - **Anthropic**: Get a key at [console.anthropic.com](https://console.anthropic.com)

API keys are encrypted at rest using AES-GCM.

### Configurable Cloud Models

You can override the default cloud models in SharedPreferences:

| Provider | Default Model | Preference Key |
|----------|--------------|----------------|
| Gemini | gemini-2.0-flash | `gemini_model` |
| OpenAI | gpt-4o-mini | `openai_model` |
| Anthropic | claude-3-haiku-20240307 | `anthropic_model` |

## Building for Release

```bash
# With signing configured
flutter build apk --release

# Without signing (uses debug keys)
flutter build apk --release
```

The release build includes:
- R8 code shrinking and obfuscation
- ProGuard rules for Flutter, Drift, SQLCipher
- Release signing (when configured)

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run analyzer
flutter analyze
```

Currently **133 tests** covering:
- Analysis service (keyword extraction, summarization)
- Cloud analysis service (provider configuration, fallback)
- Backup encryption (AES-GCM, key wrapping)
- Embedding service (TF-IDF, cosine similarity)
- Memory model (serialization, roundtrip)
- Vector index (search, remove, rebuild)
- Encrypted preferences (encrypt/decrypt, key persistence)
- Settings service (defaults, persistence, encrypted API keys)
- Overlay state (copyWith, clear flags)

## Blocking Apps

The app blocks overlay on sensitive apps by default:

- **Indian banking**: HDFC, SBI, ICICI, Axis, Kotak, etc.
- **International banking**: Chase, Wells Fargo, BofA, Citi, etc.
- **UPI/Wallets**: Google Pay, PhonePe, Paytm, Amazon Pay
- **Password managers**: LastPass, Dashlane, 1Password, Bitwarden
- **Payment platforms**: PayPal, Stripe, Venmo, Cash App, Revolut
- **Crypto exchanges**: Coinbase, Binance, Kraken, Gemini

You can customize this list in Settings > Privacy > Blocked Apps.

## Data Retention

Cache files are cleaned up daily based on the retention period (default: 30 days). You can configure this in the app's data retention settings.

## License

Private — not for distribution.
