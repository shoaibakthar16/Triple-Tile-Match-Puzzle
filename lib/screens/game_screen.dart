import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:triple_tile_match_puzzle/services/ad_service.dart';
import 'package:triple_tile_match_puzzle/game/game.dart';
import 'package:triple_tile_match_puzzle/game/managers/level_manager.dart';
import 'package:triple_tile_match_puzzle/services/game_provider.dart';
import 'package:flame/game.dart';
import 'package:triple_tile_match_puzzle/widgets/settings_dialog.dart';
import 'package:triple_tile_match_puzzle/utils/constants.dart';
import 'package:triple_tile_match_puzzle/services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final int? initialLevel;
  const GameScreen({super.key, this.initialLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late TileMatchGame _game;
  late int _playingLevel;
  int _levelCycleId = 1;
  int _failsOnCurrentLevel = 0;
  DateTime _levelStartTime = DateTime.now();

  bool _showHammerMessage = false;
  String? _activePowerUp;

  bool _prevGameOver = false;

  // Power-up usage tracking (max 2 per level)
  final Map<String, int> _powerUpUses = {
    'UNDO': 0,
    'SHUF': 0,
    'HAMMER': 0,
    'MAGNET': 0,
  };



  // Flying coins animation state
  final GlobalKey _coinBadgeKey = GlobalKey();
  final GlobalKey _winCoinKey = GlobalKey();
  final List<Widget> _flyingCoins = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = Provider.of<GameProvider>(context, listen: false);

    _playingLevel = widget.initialLevel ?? provider.currentLevel;

    // Ensure the game logic starts at the correct saved level
    LevelManager.currentLevel = _playingLevel;

    // Start background music and notify provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        provider.setGameActive(true);
        AudioManager.playBgm(provider.isMusicEnabled);
      }
    });

    _game = TileMatchGame(
      onWin: (stars) {
        AudioManager.playWin(provider.isSoundEnabled);
        provider.setLevelComplete(stars, levelOverride: _playingLevel);
      },
      onLose: () {
        _failsOnCurrentLevel++;
        AudioManager.playGameOver(provider.isSoundEnabled);
        provider.setGameOver();
      },
      onLevelChanged: () {
        // Defer the rebuild to avoid 'setState during build' errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (!_game.isHammerMode) {
                _activePowerUp = null;
              }
            });
          }
        });
      },
      onLockedSlotTapped: () {
        // Player tapped the locked 7th slot — requires rewarded ad (prevents offline exploit)
        _showRewardedAd(() {
          _game.addExtraSlot();
          if (mounted) setState(() {});
        });
      },
    );


  }

  void _showInterstitialAd({
    required VoidCallback onComplete,
    Duration? levelPlayDuration,
  }) {
    AdService.tryShowInterstitial(
      currentLevel: _playingLevel,
      levelCycleId: _levelCycleId,
      isLevelCompleteTrigger: true,
      levelPlayDuration: levelPlayDuration,
      onComplete: onComplete,
    );
  }

  void _showLoseInterstitialIfEligible() {
    AdService.tryShowInterstitial(
      currentLevel: _playingLevel,
      levelCycleId: _levelCycleId,
      isLevelCompleteTrigger: false,
      failCountInLevel: _failsOnCurrentLevel,
      onComplete: () {},
    );
  }

  void _showRewardedAd(VoidCallback onReward) {
    // Check connectivity first to prevent offline exploit
    AdService.hasInternetConnection().then((hasConnection) {
      if (!hasConnection) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      // Online — show the ad
      AdService.showRewarded(
        onReward: () {
          onReward();
          // After a successful rewarded flow, also attempt an interstitial.
          // Uses existing ad service guards to avoid overlap or invalid states.
          AdService.showInterstitial(onComplete: () {});
        },
        onNoConnection: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onInterrupted: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Ad interrupted. Please watch again.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    });
  }

  void _proceedToNextLevel(GameProvider provider) {
    _playingLevel = provider.currentLevel;
    _game.resetLevel(_playingLevel);
    _levelCycleId++;
    _failsOnCurrentLevel = 0;
    _levelStartTime = DateTime.now();
    _resetLevelState();

    // Then update provider state
    if (widget.initialLevel == null) {
      provider.nextLevel();
    } else {
      provider.resetGame();
    }
  }

  /// Resets per-level state: power-up usage counts and 7th slot unlock.
  void _resetLevelState() {
    setState(() {
      _powerUpUses.updateAll((key, value) => 0);
    });
  }

  /// Shows a "Limit Reached" snackbar when power-up max uses exceeded.
  void _showLimitReachedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Limit reached (2 per level)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    AudioManager.stopBgm();

    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.setGameActive(false);


    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioManager.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.resumeBgm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        // Detect when game over state activates
        if (provider.isGameOver && !_prevGameOver) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Lose-triggered interstitial policy:
              // show only on fail #2, #4, #6... for the same level.
              _showLoseInterstitialIfEligible();
            }
          });
        }
        _prevGameOver = provider.isGameOver;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E2841), // Fallback base color
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/background.png'),
                fit: BoxFit.cover,
                // Removed heavy colorFilter so the mountains are clearly visible
              ),
            ),
            child: Stack(
              children: [
                // 1. GAME ENGINE
                Positioned.fill(
                  child: RepaintBoundary(child: GameWidget(game: _game)),
                ),
                // 2. OVERLAY UI
                RepaintBoundary(child: _buildOverlayUI(provider)),
                // 3. LOSE OVERLAY (Countdown Revive)
                if (provider.isGameOver)
                  RepaintBoundary(child: _buildLoseOverlay(provider)),
                // 4. HAMMER MODE OVERLAY
                if (_showHammerMessage)
                  RepaintBoundary(child: _buildHammerModeOverlay()),
                // 5. WIN OVERLAY
                if (provider.isLevelComplete)
                  RepaintBoundary(child: _buildWinOverlay(provider)),
                // 6. FLYING COINS ANIMATION
                ..._flyingCoins,
                _buildBannerOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerOverlay() {
    if (!GameConstants.isMobilePlayer) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: UnityBannerAd(
            key: const ValueKey('game_overlay_banner'),
            placementId: AdService.bannerPlacementId,
            size: BannerSize.standard,
            onLoad: (placementId) => debugPrint('Banner loaded: $placementId'),
            onFailed: (placementId, error, message) =>
                debugPrint('Banner failed: $placementId $error $message'),
          ),
        ),
      ),
    );
  }

  Widget _buildHammerModeOverlay() {
    return Center(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hardware_rounded,
                        color: Colors.orange,
                        size: 80,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'HAMMER READY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlayUI(GameProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            // ── TOP BAR ──
            Row(
              children: [
                // Back button
                _buildCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 44,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8),
                // Settings button
                _buildCircleButton(
                  icon: Icons.settings_rounded,
                  size: 44,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SettingsDialog(),
                    );
                  },
                ),
                const Spacer(),
                // Level label centered
                Text(
                  'Level $_playingLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
                const Spacer(),
                // Coin display
                _buildCoinBadge(provider),
              ],
            ),

            const Spacer(),

            // ── BOTTOM POWER-UPS BAR (4 power-ups + 7th slot unlock) ──
            Padding(
              padding: const EdgeInsets.only(bottom: 62),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  // 1. Undo (max 2 per level)
                  _buildBottomPowerUp(
                    icon: Icons.replay_rounded,
                    label: 'UNDO',
                    currentCoins: provider.coins,
                    cost: GameConstants.undoCost,
                    color: Colors.orangeAccent,
                    usesLeft: GameConstants.maxPowerUpUses - (_powerUpUses['UNDO'] ?? 0),
                    onTap: () {
                      if ((_powerUpUses['UNDO'] ?? 0) >= GameConstants.maxPowerUpUses) {
                        _showLimitReachedMessage();
                        return;
                      }
                      if (provider.coins >= GameConstants.undoCost) {
                        if (_game.undo()) {
                          provider.spendCoins(GameConstants.undoCost);
                          _powerUpUses['UNDO'] = (_powerUpUses['UNDO'] ?? 0) + 1;
                          _showTemporaryGlow('UNDO');
                        }
                      } else {
                        _showRewardedAd(() {
                          if (_game.undo()) {
                            _powerUpUses['UNDO'] = (_powerUpUses['UNDO'] ?? 0) + 1;
                            _showTemporaryGlow('UNDO');
                          }
                        });
                      }
                    },
                  ),
                  // 2. Shuffle (max 2 per level)
                  _buildBottomPowerUp(
                    icon: Icons.shuffle_rounded,
                    label: 'SHUF',
                    currentCoins: provider.coins,
                    cost: GameConstants.shuffleCost,
                    color: Colors.lightBlueAccent,
                    usesLeft: GameConstants.maxPowerUpUses - (_powerUpUses['SHUF'] ?? 0),
                    onTap: () {
                      if ((_powerUpUses['SHUF'] ?? 0) >= GameConstants.maxPowerUpUses) {
                        _showLimitReachedMessage();
                        return;
                      }
                      if (provider.spendCoins(GameConstants.shuffleCost)) {
                        _game.shuffle();
                        _powerUpUses['SHUF'] = (_powerUpUses['SHUF'] ?? 0) + 1;
                        _showTemporaryGlow('SHUF');
                      } else {
                        _showRewardedAd(() {
                          _game.shuffle();
                          _powerUpUses['SHUF'] = (_powerUpUses['SHUF'] ?? 0) + 1;
                          _showTemporaryGlow('SHUF');
                        });
                      }
                    },
                  ),
                  // 3. Magnet (max 2 per level)
                  _buildBottomPowerUp(
                    icon: Icons.auto_awesome_rounded,
                    label: 'MAGNET',
                    currentCoins: provider.coins,
                    cost: GameConstants.magnetCost,
                    color: Colors.purpleAccent,
                    usesLeft: GameConstants.maxPowerUpUses - (_powerUpUses['MAGNET'] ?? 0),
                    onTap: () {
                      if ((_powerUpUses['MAGNET'] ?? 0) >= GameConstants.maxPowerUpUses) {
                        _showLimitReachedMessage();
                        return;
                      }
                      if (provider.spendCoins(GameConstants.magnetCost)) {
                        _game.useMagnet();
                        _powerUpUses['MAGNET'] = (_powerUpUses['MAGNET'] ?? 0) + 1;
                        _showTemporaryGlow('MAGNET');
                      } else {
                        _showRewardedAd(() {
                          _game.useMagnet();
                          _powerUpUses['MAGNET'] = (_powerUpUses['MAGNET'] ?? 0) + 1;
                          _showTemporaryGlow('MAGNET');
                        });
                      }
                    },
                  ),
                  // 4. Hammer (max 2 per level)
                  _buildBottomPowerUp(
                    icon: Icons.hardware_rounded,
                    label: 'HAMMER',
                    currentCoins: provider.coins,
                    cost: GameConstants.hammerCost,
                    color: Colors.redAccent,
                    usesLeft: GameConstants.maxPowerUpUses - (_powerUpUses['HAMMER'] ?? 0),
                    onTap: () {
                      if ((_powerUpUses['HAMMER'] ?? 0) >= GameConstants.maxPowerUpUses) {
                        _showLimitReachedMessage();
                        return;
                      }
                      if (provider.spendCoins(GameConstants.hammerCost)) {
                        _powerUpUses['HAMMER'] = (_powerUpUses['HAMMER'] ?? 0) + 1;
                        setState(() {
                          _game.activateHammer();
                          _activePowerUp = 'HAMMER';
                          _showHammerMessage = true;
                        });
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted) {
                            setState(() {
                              _showHammerMessage = false;
                            });
                          }
                        });
                      } else {
                        _showRewardedAd(() {
                          _powerUpUses['HAMMER'] = (_powerUpUses['HAMMER'] ?? 0) + 1;
                          setState(() {
                            _game.activateHammer();
                            _activePowerUp = 'HAMMER';
                            _showHammerMessage = true;
                          });
                          Future.delayed(
                            const Duration(milliseconds: 1500),
                            () {
                              if (mounted) {
                                setState(() {
                                  _showHammerMessage = false;
                                });
                              }
                            },
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Individual circle button (header) ──
  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveSize = (size * (screenWidth / 375)).clamp(36.0, 56.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: responsiveSize,
        height: responsiveSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C3E6D).withValues(alpha: 0.85),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: responsiveSize * 0.5),
      ),
    );
  }

  // ── Coin badge display ──
  Widget _buildCoinBadge(GameProvider provider) {
    return KeyedSubtree(
      key: _coinBadgeKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E6D).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${provider.coins}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom power-up button with label ──
  Widget _buildBottomPowerUp({
    required IconData icon,
    required VoidCallback onTap,
    required int currentCoins,
    String? label,
    int? cost,
    Color color = Colors.white,
    int? usesLeft,
  }) {
    final bool canAfford = cost == null || currentCoins >= cost;
    final bool isDisabled = usesLeft != null && usesLeft <= 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth / 7.5).clamp(42.0, 62.0);
    final iconSize = buttonSize * 0.5;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: SizedBox(
          width: buttonSize + 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle icon with cost badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A2A2A).withValues(alpha: 0.9),
                          const Color(0xFF1E1E2C).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  // Cost / AD badge
                  if (cost != null)
                    Positioned(
                      bottom: -2,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? const Color(0xFF2C3E6D)
                              : Colors.green.shade800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canAfford
                                ? Colors.amber.withValues(alpha: 0.5)
                                : Colors.lightGreenAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              canAfford
                                  ? Icons.monetization_on
                                  : Icons.play_circle_fill_rounded,
                              color: canAfford
                                  ? Colors.amber
                                  : Colors.lightGreenAccent,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              canAfford ? '$cost' : 'AD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Uses left badge (top-left)
                  if (usesLeft != null)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: usesLeft > 0
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.red.shade700,
                          border: Border.all(
                            color: usesLeft > 0
                                ? color.withValues(alpha: 0.6)
                                : Colors.red.shade900,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$usesLeft',
                            style: TextStyle(
                              color: usesLeft > 0
                                  ? Colors.black87
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (label != null) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _animateFlyingCoins(int amount, VoidCallback onComplete) {
    RenderBox? startBox =
        _winCoinKey.currentContext?.findRenderObject() as RenderBox?;
    RenderBox? endBox =
        _coinBadgeKey.currentContext?.findRenderObject() as RenderBox?;

    if (startBox == null || endBox == null) {
      onComplete();
      return;
    }

    final Offset startPos = startBox.localToGlobal(Offset.zero);
    final Offset endPos = endBox.localToGlobal(Offset.zero);

    // Spawn 10 staggered coins
    const int coinCount = 12;
    for (int i = 0; i < coinCount; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (!mounted) return;

        final coinId = DateTime.now().millisecondsSinceEpoch + i;
        final coinWidget = _buildFlyingCoin(
          id: coinId,
          start: startPos,
          end: endPos,
          onComplete: () {
            setState(() {
              _flyingCoins.removeWhere((w) {
                if (w is AnimatedPositioned) {
                  return w.key == ValueKey(coinId);
                }
                return false;
              });
            });
            // If it's the last coin, call the final complete callback
            if (i == coinCount - 1) {
              onComplete();
            }
          },
        );

        setState(() {
          _flyingCoins.add(coinWidget);
        });
      });
    }
  }

  Widget _buildFlyingCoin({
    required int id,
    required Offset start,
    required Offset end,
    required VoidCallback onComplete,
  }) {
    return _FlyingCoinWidget(
      key: ValueKey(id),
      start: start,
      end: end,
      onComplete: onComplete,
    );
  }

  void _showTemporaryGlow(String label) {
    setState(() {
      _activePowerUp = label;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _activePowerUp == label) {
        setState(() {
          _activePowerUp = null;
        });
      }
    });
  }

  Widget _buildWinOverlay(GameProvider provider) {
    final coinsEarned = provider.lastEarnedStars * 50;

    return _buildOverlayWrapper(
      child: _buildGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Stars
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isEarned = index < provider.lastEarnedStars;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 300)),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        isEarned
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: isEarned ? Colors.amber : Colors.white24,
                        size: 70,
                        shadows: isEarned
                            ? [
                                Shadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                ),
                              ]
                            : null,
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Text(
                    'EXCELLENT!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            KeyedSubtree(
              key: _winCoinKey,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$coinsEarned Coins',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 15,
              children: [
                _buildActionButton(
                  'WATCH AD 2x',
                  Colors.green.shade600,
                  () {
                    _showRewardedAd(() {
                      // 2x means double the base earned coins
                      provider.addCoins(coinsEarned * 2);
                      _animateFlyingCoins(coinsEarned * 2, () {
                        _proceedToNextLevel(provider);
                      });
                    });
                  },
                  icon: Icons.play_circle_fill_rounded,
                ),
                _buildActionButton(
                  'NEXT LEVEL',
                  Colors.orange.shade600,
                  () {
                    // Always add base coins first, then optionally show ad
                    provider.addCoins(coinsEarned);
                    final levelPlayDuration = DateTime.now().difference(
                      _levelStartTime,
                    );
                    _showInterstitialAd(
                      levelPlayDuration: levelPlayDuration,
                      onComplete: () {
                        _proceedToNextLevel(provider);
                      },
                    );
                  },
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoseOverlay(GameProvider provider) {
    return _buildOverlayWrapper(
      child: _buildGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: Colors.white70,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              'OUT OF MOVES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your tray is full!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 15,
              children: [
                _buildActionButton('RETRY', Colors.blueGrey.shade600, () {
                  _game.resetLevel();
                  _levelCycleId++;
                  _levelStartTime = DateTime.now();
                  _resetLevelState();
                  provider.resetGame();
                }, icon: Icons.refresh_rounded),
                _buildActionButton(
                  'REVIVE (AD)',
                  Colors.green.shade600,
                  () {
                    // Requires rewarded ad (prevents offline exploit)
                    _showRewardedAd(() {
                      _game.revive();
                      provider.resetGame();
                    });
                  },
                  icon: Icons.favorite_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayWrapper({required Widget child}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      width: double.infinity,
      height: double.infinity,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, double width = 350}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onTap, {
    IconData? icon,
    bool isFullWidth = false,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              onTap();
            }
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
          height: 60,
          width: isFullWidth ? double.infinity : 155,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlyingCoinWidget extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const _FlyingCoinWidget({
    super.key,
    required this.start,
    required this.end,
    required this.onComplete,
  });

  @override
  State<_FlyingCoinWidget> createState() => _FlyingCoinWidgetState();
}

class _FlyingCoinWidgetState extends State<_FlyingCoinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Offset _burstOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initial random burst offset
    final random = Random();
    _burstOffset = Offset(
      (random.nextDouble() - 0.5) * 150,
      (random.nextDouble() - 0.5) * 150,
    );

    // Position animation: start -> burst -> end
    _positionAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: widget.start,
          end: widget.start + _burstOffset,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: widget.start + _burstOffset,
          end: widget.start + _burstOffset, // Pause briefly at burst peak
        ),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: widget.start + _burstOffset,
          end: widget.end,
        ).chain(CurveTween(curve: Curves.easeInOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
