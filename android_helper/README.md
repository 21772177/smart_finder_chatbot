# Android Helper - Accessibility Service

Android helper app that uses AccessibilityService to automatically capture liked videos and posts from YouTube, Instagram, and Facebook, then saves them to Smart Finder chatbot.

## Architecture

### Overview
The Android Helper uses Android's AccessibilityService API to detect when users interact with like/save buttons on supported apps, then automatically captures the current content URL and sends it to the Smart Finder backend.

### Flow
1. User installs helper app and grants Accessibility permission
2. When user taps 'like' or 'save' on YouTube/Instagram/Facebook:
   - AccessibilityService detects the action
   - Helper captures current URL (or share intent)
   - Helper POSTs to backend `/api/saveLink` endpoint
3. Backend triggers indexing or auto-sync

## Implementation Requirements

### Android App Structure

```
android_helper/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── java/com/smartfinder/helper/
│   │       │   ├── MainActivity.kt
│   │       │   ├── AutoSaveService.kt (AccessibilityService)
│   │       │   └── BackendSync.kt
│   │       ├── res/
│   │       │   ├── xml/
│   │       │   │   └── accessibility_service_config.xml
│   │       │   └── values/
│   │       │       └── strings.xml
│   │       └── AndroidManifest.xml
│   └── build.gradle
└── README.md
```

### Key Components

#### 1. AccessibilityService (AutoSaveService.kt)

```kotlin
class AutoSaveService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Detect like/save button clicks
        // Extract current URL
        // Send to backend
    }
    
    override fun onInterrupt() {
        // Handle interruption
    }
}
```

#### 2. Backend Integration (BackendSync.kt)

```kotlin
class BackendSync {
    suspend fun saveLink(url: String, metadata: Map<String, Any>) {
        // POST to https://us-central1-buildkit-1695f.cloudfunctions.net/api/api/saveLink
        // Include user ID and device token
    }
}
```

#### 3. AndroidManifest.xml

```xml
<service
    android:name=".AutoSaveService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
```

### Permissions Required

- `BIND_ACCESSIBILITY_SERVICE` - For AccessibilityService
- `INTERNET` - For backend communication
- `ACCESS_NETWORK_STATE` - For network status checks

### User Privacy & Consent

**IMPORTANT**: 
- Must show clear opt-in dialog explaining what the service does
- Must request explicit user consent before enabling
- Must allow users to disable at any time
- Must respect user privacy and only capture explicitly liked/saved content

### Backend Endpoint

The helper app should POST to:
```
POST /api/saveLink
{
  "userId": "user_id",
  "deviceToken": "device_token",
  "url": "https://youtube.com/watch?v=...",
  "platform": "youtube",
  "metadata": {
    "title": "Video Title",
    "timestamp": "2025-11-18T..."
  }
}
```

## Development Status

**Status**: ⚠️ Architecture defined, implementation pending

This requires:
1. Android Studio setup
2. Kotlin/Java development
3. AccessibilityService implementation
4. Backend integration
5. Testing on physical devices
6. Google Play Store submission (if publishing)

## Alternative Approach

Instead of AccessibilityService, consider:
- **Share Intent Handler**: User shares content → Helper captures share intent
- **Notification Listener**: Listen for app notifications about saved content
- **Deep Link Integration**: Apps open Smart Finder via deep link

## Notes

- AccessibilityService requires explicit user permission
- Must handle different app versions and UI changes
- Should include error handling and retry logic
- Should batch requests to reduce API calls
- Should work offline and sync when online

---

**Recommendation**: Start with Share Intent Handler approach (simpler, more reliable) before implementing full AccessibilityService.

