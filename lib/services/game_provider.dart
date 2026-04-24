import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GameProvider extends ChangeNotifier {
  int _coins = 100;
  int _currentLevel = 1;
  bool _isGameOver = false;
  bool _isLevelComplete = false;
  int _lastEarnedStars = 0;
  final Map<int, int> _starsPerLevel = {};
  bool _isGameActive = false;
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;

  int get coins => _coins;
  int get currentLevel => _currentLevel;
  bool get isGameOver => _isGameOver;
  bool get isLevelComplete => _isLevelComplete;
  int get lastEarnedStars => _lastEarnedStars;
  bool get isGameActive => _isGameActive;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicEnabled => _isMusicEnabled;

  GameProvider() {
    _loadData();
  }

  Future<void> initialize() async {}

  void _loadData() {
    final box = Hive.box('game_state');
    _coins = box.get('coins', defaultValue: 100);
    _currentLevel = box.get('currentLevel', defaultValue: 1);
    _isSoundEnabled = box.get('isSoundEnabled', defaultValue: true);
    _isMusicEnabled = box.get('isMusicEnabled', defaultValue: true);

    final savedStars = box.get('starsPerLevel', defaultValue: <int, int>{});
    if (savedStars is Map) {
      savedStars.forEach((key, value) {
        _starsPerLevel[key as int] = value as int;
      });
    }

    notifyListeners();
  }

  int getStarsForLevel(int level) => _starsPerLevel[level] ?? 0;

  void addCoins(int amount) {
    _coins += amount;
    Hive.box('game_state').put('coins', _coins);
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      Hive.box('game_state').put('coins', _coins);
      notifyListeners();
      return true;
    }
    return false;
  }

  void nextLevel() {
    _isLevelComplete = false;
    _isGameOver = false;
    _lastEarnedStars = 0;
    notifyListeners();
  }

  void setLevelComplete(int stars, {int? levelOverride}) {
    _isLevelComplete = true;
    _lastEarnedStars = stars;

    int completedLevel = levelOverride ?? _currentLevel;

    final currentBest = _starsPerLevel[completedLevel] ?? 0;
    if (stars > currentBest) {
      _starsPerLevel[completedLevel] = stars;
      Hive.box('game_state').put('starsPerLevel', _starsPerLevel);
    }

    if (completedLevel == _currentLevel) {
      _currentLevel++;
      Hive.box('game_state').put('currentLevel', _currentLevel);
    }

    notifyListeners();
  }

  void setGameOver() {
    _isGameOver = true;
    notifyListeners();
  }

  void setGameActive(bool active) {
    _isGameActive = active;
    // BGM is controlled entirely by the game engine (game.dart)
    // No BGM start/stop here to avoid duplicate control
    notifyListeners();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    Hive.box('game_state').put('isSoundEnabled', _isSoundEnabled);
    notifyListeners();
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    Hive.box('game_state').put('isMusicEnabled', _isMusicEnabled);
    notifyListeners();
  }

  void resetGame() {
    _isGameOver = false;
    _isLevelComplete = false;
    _lastEarnedStars = 0;
    notifyListeners();
  }
}
