import 'package:flutter/foundation.dart';

class GameConstants {
  static bool get isMobilePlayer =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const double tilePadding = 8.0;
  static const double trayHeight = 80.0;
  static const int baseTraySlots = 7; // Tray always renders 7 slots
  static const int maxTraySlots = 7;

  // Hive box names
  static const String settingsBox = 'settings';
  static const String gameStateBox = 'game_state';

  // Level related
  static const int initialLevel = 1;

  // Power-up Costs (rebalanced)
  static const int undoCost = 200;
  static const int shuffleCost = 300;
  static const int hammerCost = 500;
  static const int magnetCost = 400;

  // Legacy costs (unused but kept for reference)
  static const int hintCost = 150;
  static const int extraSlotCost = 300;
  static const int reviveCost = 300;

  // Power-up usage limit per level
  static const int maxPowerUpUses = 2;

  // Unity Ads IDs
  static const bool useTestAds = false; // Production ads
  static const String androidGameId = '6076195';
  static const String iosGameId = '6076194';
  
  static const String bannerAndroidId = 'Banner_Android';
  static const String bannerIOSId = 'Banner_iOS';
  static const String interstitialAndroidId = 'Interstitial_Android';
  static const String interstitialIOSId = 'Interstitial_iOS';
  static const String rewardedAndroidId = 'Rewarded_Android';
  static const String rewardedIOSId = 'Rewarded_iOS';

  // Legal Links
  static const String privacyPolicyUrl =
      'https://shoaibakthar16.github.io/Triple-Tile/privacy-policy.html';
  static const String termsOfServiceUrl =
      'https://shoaibakthar16.github.io/Triple-Tile/terms-of-service.html';
}
