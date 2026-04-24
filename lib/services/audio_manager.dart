import 'package:flame_audio/flame_audio.dart';

/// Manages all game audio: background music, win/lose sound effects.
class AudioManager {
  static bool _initialized = false;
  static bool _bgmPlaying = false;
  static AudioPool? _tapPool;

  /// Preload all audio files for instant playback.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'background song.mp3',
        'game win.mp3',
        'game over.mp3',
        'tile disapper.mp3',
      ]);
      _tapPool = await FlameAudio.createPool(
        'tile disapper.mp3',
        minPlayers: 3,
        maxPlayers: 5,
      );
      _initialized = true;
    } catch (_) {
      // Silently ignore if audio files are missing
    }
  }

  /// Start looping background music.
  static void playBgm([bool enabled = true]) {
    if (!_initialized || _bgmPlaying || !enabled) return;
    try {
      FlameAudio.bgm.play('background song.mp3', volume: 0.4);
      _bgmPlaying = true;
    } catch (_) {}
  }

  /// Stop background music.
  static void stopBgm() {
    if (!_bgmPlaying) return;
    try {
      FlameAudio.bgm.stop();
      _bgmPlaying = false;
    } catch (_) {}
  }

  /// Pause background music (e.g. when app goes to background).
  static void pauseBgm() {
    if (!_bgmPlaying) return;
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  /// Resume background music.
  static void resumeBgm() {
    if (!_bgmPlaying) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// Play the win sound effect.
  static void playWin([bool enabled = true]) {
    if (!_initialized || !enabled) return;
    try {
      FlameAudio.play('game win.mp3', volume: 0.8);
    } catch (_) {}
  }

  /// Play the game over sound effect.
  static void playGameOver([bool enabled = true]) {
    if (!_initialized || !enabled) return;
    try {
      FlameAudio.play('game over.mp3', volume: 0.8);
    } catch (_) {}
  }

  /// Play an instant tile match sound effect.
  static void playTileMatch([bool enabled = true]) {
    if (!_initialized || _tapPool == null || !enabled) return;
    try {
      _tapPool?.start(volume: 0.5);
    } catch (_) {}
  }


  /// Clean up all resources.
  static void dispose() {
    try {
      FlameAudio.bgm.stop();
      _bgmPlaying = false;
    } catch (_) {}
  }
}
