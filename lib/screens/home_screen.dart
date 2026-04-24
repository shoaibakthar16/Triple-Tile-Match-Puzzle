import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triple_tile_match_puzzle/screens/game_screen.dart';
import 'package:triple_tile_match_puzzle/services/game_provider.dart';
import 'package:triple_tile_match_puzzle/services/ad_service.dart';
import 'package:triple_tile_match_puzzle/utils/constants.dart';
import 'package:triple_tile_match_puzzle/widgets/settings_dialog.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return Stack(
            children: [
              // Dynamic Background
              _buildAnimatedBackground(gameProvider),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Color(0x10000000),
                      Color(0x65000000),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopSection(gameProvider),
                    _buildLogoHero(),
                    const Spacer(flex: 8),
                    _buildAnimatedPlayButton(context),
                    const Spacer(flex: 12),
                  ],
                ),
              ),
              _buildBannerOverlay(
                onLoadTag: 'Home Banner loaded',
                onFailTag: 'Home Banner failed',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerOverlay({
    required String onLoadTag,
    required String onFailTag,
  }) {
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
            key: const ValueKey('home_overlay_banner'),
            placementId: AdService.bannerPlacementId,
            size: BannerSize.standard,
            onLoad: (placementId) => debugPrint('$onLoadTag: $placementId'),
            onFailed: (placementId, error, message) =>
                debugPrint('$onFailTag: $placementId $error $message'),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(GameProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2841), // Base fallback color
        image: const DecorationImage(
          image: AssetImage('assets/images/backgrounds/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: FloatingTilesPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 0),
      child: Column(
        children: [
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Triple Tiles',
            style: TextStyle(
              color: Color(0xFFF8FBFF),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              shadows: [
                Shadow(
                  color: Color(0xB3000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          const Text(
            'Match Puzzle',
            style: TextStyle(
              color: Color(0xFFF0F5FF),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.0,
              shadows: [
                Shadow(
                  color: Color(0x77000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Coin Counter with Glow
          _buildGlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    colors: [Colors.amber, Colors.orangeAccent],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${gameProvider.coins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Settings Button
          _buildGlassIconButton(Icons.settings_rounded, () {
            showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            );
          }, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildAnimatedPlayButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = 1.0 + sin(_controller.value * 2 * pi) * 0.05;
            final screenWidth = MediaQuery.of(context).size.width;
            final buttonWidth = (screenWidth * 0.6).clamp(200.0, 350.0);
            final fontSize = (buttonWidth * 0.12).clamp(18.0, 32.0);

            return Transform.scale(
              scale: pulse,
              child: Container(
                width: buttonWidth,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurpleAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 20 * pulse,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Consumer<GameProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        'LEVEL ${provider.currentLevel}',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E6D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassIconButton(
    IconData icon,
    VoidCallback onPressed, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class FloatingTilesPainter extends CustomPainter {
  final double animationValue;

  const FloatingTilesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 15; i++) {
      final x =
          (random.nextDouble() * size.width +
              animationValue * 100 * (i % 2 == 0 ? 1 : -1)) %
          size.width;
      final y =
          (random.nextDouble() * size.height + animationValue * 50) %
          size.height;
      final rotation = animationValue * 2 * pi * (i % 3 == 0 ? 1 : -1);
      final scale = 0.5 + random.nextDouble();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(scale);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -20, 40, 40),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
