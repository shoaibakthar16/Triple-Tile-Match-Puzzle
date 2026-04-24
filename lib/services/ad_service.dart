import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:triple_tile_match_puzzle/utils/constants.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdService {
  static bool _isInitialized = false;
  static bool _isShowingAd = false;
  static final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);
  static final Set<int> _interstitialShownCycles = <int>{};
  static final _AdLifecycleObserver _lifecycleObserver = _AdLifecycleObserver();

  static const int onboardingAdBlockUntilLevel = 3;

  static String get _gameId =>
      Platform.isAndroid ? GameConstants.androidGameId : GameConstants.iosGameId;

  static String get bannerPlacementId =>
      Platform.isAndroid ? GameConstants.bannerAndroidId : GameConstants.bannerIOSId;

  static String get interstitialPlacementId =>
      Platform.isAndroid
          ? GameConstants.interstitialAndroidId
          : GameConstants.interstitialIOSId;

  static String get rewardedPlacementId =>
      Platform.isAndroid
          ? GameConstants.rewardedAndroidId
          : GameConstants.rewardedIOSId;

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> initialize() async {
    if (!GameConstants.isMobilePlayer || _isInitialized) return;

    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    UnityAds.init(
      gameId: _gameId,
      testMode: GameConstants.useTestAds,
      onComplete: () {
        _isInitialized = true;
        adsReady.value = true;
        debugPrint('Unity Ads initialized successfully');
        _loadInterstitial();
      },
      onFailed: (error, message) {
        debugPrint('Unity Ads init failed: $error $message');
        adsReady.value = false;
      },
    );
  }

  static bool _interstitialLoaded = false;

  static void _loadInterstitial() {
    UnityAds.load(
      placementId: interstitialPlacementId,
      onComplete: (placementId) {
        _interstitialLoaded = true;
        debugPrint('Interstitial loaded: $placementId');
      },
      onFailed: (placementId, error, message) {
        _interstitialLoaded = false;
        debugPrint('Interstitial load failed: $placementId $error $message');
      },
    );
  }

  static void showInterstitial({required VoidCallback onComplete}) {
    if (!GameConstants.isMobilePlayer || !_isInitialized) {
      onComplete();
      return;
    }
    if (_isShowingAd) {
      onComplete();
      return;
    }

    if (_interstitialLoaded) {
      _isShowingAd = true;
      UnityAds.showVideoAd(
        placementId: interstitialPlacementId,
        onComplete: (placementId) {
          _isShowingAd = false;
          _interstitialLoaded = false;
          _loadInterstitial();
          onComplete();
        },
        onSkipped: (placementId) {
          _isShowingAd = false;
          _interstitialLoaded = false;
          _loadInterstitial();
          onComplete();
        },
        onFailed: (placementId, error, message) {
          _isShowingAd = false;
          debugPrint('Interstitial show failed: $error $message');
          _interstitialLoaded = false;
          _loadInterstitial();
          onComplete();
        },
      );
    } else {
      _loadInterstitial();
      onComplete();
    }
  }

  static bool canShowInterstitial({
    required int currentLevel,
    required int levelCycleId,
    required bool isLevelCompleteTrigger,
    int? failCountInLevel,
    Duration? levelPlayDuration,
  }) {
    if (!GameConstants.isMobilePlayer || !_isInitialized || !_interstitialLoaded) {
      return false;
    }
    if (_isShowingAd) {
      return false;
    }
    if (currentLevel <= onboardingAdBlockUntilLevel) {
      return false;
    }
    if (_interstitialShownCycles.contains(levelCycleId)) {
      return false;
    }

    if (isLevelCompleteTrigger) {
      final isSlowCompletion =
          levelPlayDuration != null &&
          levelPlayDuration >= const Duration(seconds: 90);
      if (!isSlowCompletion && currentLevel % 3 != 0) {
        return false;
      }
    } else {
      if (failCountInLevel == null || failCountInLevel < 2 || failCountInLevel % 2 != 0) {
        return false;
      }
    }

    return true;
  }

  static void tryShowInterstitial({
    required int currentLevel,
    required int levelCycleId,
    required bool isLevelCompleteTrigger,
    int? failCountInLevel,
    Duration? levelPlayDuration,
    required VoidCallback onComplete,
  }) {
    if (!canShowInterstitial(
      currentLevel: currentLevel,
      levelCycleId: levelCycleId,
      isLevelCompleteTrigger: isLevelCompleteTrigger,
      failCountInLevel: failCountInLevel,
      levelPlayDuration: levelPlayDuration,
    )) {
      onComplete();
      return;
    }

    showInterstitial(
      onComplete: () {
        _interstitialShownCycles.add(levelCycleId);
        onComplete();
      },
    );
  }

  static bool _rewardedInProgress = false;
  static bool _rewardedCompleted = false;
  static VoidCallback? _pendingRewardCallback;
  static VoidCallback? _pendingInterruptedCallback;

  static void showRewarded({
    required VoidCallback onReward,
    VoidCallback? onNoConnection,
    VoidCallback? onInterrupted,
  }) {
    if (!GameConstants.isMobilePlayer || !_isInitialized) {
      onNoConnection?.call();
      return;
    }
    if (_isShowingAd) {
      return;
    }

    if (_interstitialLoaded) {
      _isShowingAd = true;
      _rewardedInProgress = true;
      _rewardedCompleted = false;
      _pendingRewardCallback = onReward;
      _pendingInterruptedCallback = onInterrupted;

      UnityAds.showVideoAd(
        placementId: interstitialPlacementId,
        onComplete: (placementId) {
          _rewardedCompleted = true;
          _finishRewardedFlow();
        },
        onSkipped: (placementId) {
          // Interstitials are skippable, but we still grant the reward per user request
          _rewardedCompleted = true; 
          _finishRewardedFlow();
        },
        onFailed: (placementId, error, message) {
          debugPrint('Interstitial (as Rewarded) show failed: $error $message');
          _finishRewardedFlow();
        },
      );
    } else {
      _loadInterstitial();
      onNoConnection?.call();
    }
  }

  static void _onLifecycleStateChanged(AppLifecycleState state) {
    if (!_rewardedInProgress) return;
    // Unity ad playback can trigger temporary app lifecycle transitions.
    // We trust Unity's onComplete/onSkipped/onFailed callbacks to decide reward.
    if (state == AppLifecycleState.detached) {
      _rewardedInProgress = false;
    }
  }

  static void _finishRewardedFlow() {
    _isShowingAd = false;
    _interstitialLoaded = false;
    _loadInterstitial();

    final shouldReward = _rewardedCompleted;
    final rewardCallback = _pendingRewardCallback;
    final interruptedCallback = _pendingInterruptedCallback;

    _rewardedInProgress = false;
    _rewardedCompleted = false;
    _pendingRewardCallback = null;
    _pendingInterruptedCallback = null;

    if (shouldReward) {
      rewardCallback?.call();
    } else {
      interruptedCallback?.call();
    }
  }
}

class _AdLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AdService._onLifecycleStateChanged(state);
  }
}
