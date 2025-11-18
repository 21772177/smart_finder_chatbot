# Android Helper Architecture

## Overview

The Android Helper is designed to automatically capture liked/saved content from YouTube, Instagram, and Facebook apps, then sync it to Smart Finder chatbot.

## Design Decisions

### Option 1: AccessibilityService (Complex)
- **Pros**: Fully automatic, no user interaction needed
- **Cons**: Requires special permission, complex to implement, fragile (breaks with app updates)
- **Status**: Architecture defined, not implemented

### Option 2: Share Intent Handler (Recommended)
- **Pros**: Simple, reliable, standard Android pattern
- **Cons**: Requires user to share content
- **Status**: Recommended approach

### Option 3: Notification Listener (Medium)
- **Pros**: Can detect app notifications about saved content
- **Cons**: Requires notification access permission, not all apps notify
- **Status**: Alternative approach

## Recommended Implementation: Share Intent Handler

### Flow
1. User likes/saves content in YouTube/Instagram/Facebook
2. User taps "Share" → Selects "Smart Finder"
3. Helper app receives share intent
4. Helper extracts URL and metadata
5. Helper sends to backend `/api/saveLink`
6. Backend indexes the content

### Implementation Steps

1. **Create Android Project**
   ```bash
   # In Android Studio
   - New Project → Empty Activity
   - Minimum SDK: 21 (Android 5.0)
   - Language: Kotlin
   ```

2. **Add Share Intent Filter**
   ```xml
   <activity android:name=".ShareActivity">
       <intent-filter>
           <action android:name="android.intent.action.SEND" />
           <category android:name="android.intent.category.DEFAULT" />
           <data android:mimeType="text/plain" />
       </intent-filter>
   </activity>
   ```

3. **Handle Share Intent**
   ```kotlin
   class ShareActivity : AppCompatActivity() {
       override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)
           
           val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
           if (sharedText != null) {
               // Extract URL
               // Send to backend
               finish()
           }
       }
   }
   ```

4. **Backend Integration**
   - Use Retrofit or OkHttp for HTTP requests
   - Include user authentication (device token)
   - Handle offline scenarios

## Files Structure

```
android_helper/
├── app/
│   ├── src/main/
│   │   ├── java/com/smartfinder/helper/
│   │   │   ├── MainActivity.kt
│   │   │   ├── ShareActivity.kt
│   │   │   ├── BackendService.kt
│   │   │   └── models/
│   │   │       └── LinkData.kt
│   │   ├── res/
│   │   │   └── values/
│   │   │       └── strings.xml
│   │   └── AndroidManifest.xml
│   └── build.gradle
└── README.md
```

## Backend Endpoint

The helper should POST to:
```
POST https://us-central1-buildkit-1695f.cloudfunctions.net/api/api/saveLink

Headers:
  Content-Type: application/json

Body:
{
  "userId": "user_id_or_email",
  "deviceToken": "device_token",
  "url": "https://youtube.com/watch?v=...",
  "platform": "youtube",
  "metadata": {
    "title": "Video Title",
    "sharedAt": "2025-11-18T..."
  }
}
```

## Status

**Current**: Architecture and documentation complete
**Next Steps**: 
1. Create Android Studio project
2. Implement Share Intent Handler
3. Add backend integration
4. Test on devices
5. Publish to Google Play (optional)

---

**Note**: This is a separate Android app project. It should be developed in Android Studio and can be published independently or kept as internal tool.

