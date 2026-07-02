class AppConstants {
  static const String appName = 'Second Brain';
  static const String channelOverlay = 'com.secondbrain/overlay';
  static const String channelCapture = 'com.secondbrain/capture';
  static const String channelStorage = 'com.secondbrain/storage';

  static const List<String> blockedApps = [
    'com.android.bank', // placeholder – detected dynamically
  ];

  static const int maxCaptureWidth = 1080;
}
