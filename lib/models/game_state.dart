import 'package:flutter/foundation.dart';

class LevelProgress {
  final bool completed;
  final int stars;
  final String bestTime;
  final double bestTimeSec;

  LevelProgress({
    required this.completed,
    required this.stars,
    required this.bestTime,
    required this.bestTimeSec,
  });

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'stars': stars,
        'bestTime': bestTime,
        'bestTimeSec': bestTimeSec,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        completed: json['completed'] ?? false,
        stars: json['stars'] ?? 0,
        bestTime: json['bestTime'] ?? '--:--',
        bestTimeSec: (json['bestTimeSec'] ?? 99999.0).toDouble(),
      );
}

class AchievementItem {
  final String key;
  final String title;
  final String description;
  int progress;
  int total;
  bool claimed;

  AchievementItem({
    required this.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.total,
    this.claimed = false,
  });
}

class GameState extends ChangeNotifier {
  int energy = 5;
  int maxEnergy = 5;
  int coins = 1250;
  int gems = 45;
  int streak = 24;
  int mazesSolved = 142;
  int totalStars = 389;
  int currentLevel = 27;

  String selectedMode = 'simple'; // 'simple' | 'complicated'
  String equippedTheme = 'neon';  // 'neon' | 'forest' | 'ocean' | 'lava' | 'space'
  String equippedTrail = 'default';

  List<String> unlockedThemes = ['neon'];
  int undoCount = 3;
  int hintCount = 3;

  // Settings
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticEnabled = true;
  bool darkMode = true;
  String language = 'en';

  // Stats
  int perfectRuns = 14;
  int totalTimeSec = 9240;
  int longestStreak = 8;

  // Level progress map: mode -> (levelNum -> LevelProgress)
  Map<String, Map<int, LevelProgress>> levelProgress = {
    'simple': {
      27: LevelProgress(completed: true, stars: 3, bestTime: '00:28.34', bestTimeSec: 28.34),
    },
    'complicated': {},
  };

  void setMode(String mode) {
    selectedMode = mode;
    notifyListeners();
  }

  void setLevel(int lvl) {
    currentLevel = lvl;
    notifyListeners();
  }

  void addCoins(int amount) {
    coins += amount;
    notifyListeners();
  }

  void addGems(int amount) {
    gems += amount;
    notifyListeners();
  }

  void refillEnergy() {
    energy = maxEnergy;
    notifyListeners();
  }

  bool useUndo() {
    if (undoCount > 0) {
      undoCount--;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useHint() {
    if (hintCount > 0) {
      hintCount--;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool buyAndEquipTheme(String themeId, int gemPrice) {
    if (unlockedThemes.contains(themeId)) {
      equippedTheme = themeId;
      notifyListeners();
      return true;
    }
    if (gems >= gemPrice) {
      gems -= gemPrice;
      unlockedThemes.add(themeId);
      equippedTheme = themeId;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setEquippedTheme(String themeId) {
    equippedTheme = themeId;
    if (!unlockedThemes.contains(themeId)) {
      unlockedThemes.add(themeId);
    }
    notifyListeners();
  }

  void saveLevelResult(String mode, int levelNum, int starsEarned, double timeSec, bool isPerfect, {int coinsEarned = 50, int gemsEarned = 2}) {
    if (!levelProgress.containsKey(mode)) {
      levelProgress[mode] = {};
    }

    final prev = levelProgress[mode]![levelNum] ??
        LevelProgress(completed: false, stars: 0, bestTime: '--:--', bestTimeSec: 99999);

    final bestSec = timeSec < prev.bestTimeSec ? timeSec : prev.bestTimeSec;
    final mins = (bestSec / 60).floor();
    final secs = (bestSec % 60).toStringAsFixed(2);
    final formattedTime = '${mins.toString().padLeft(2, '0')}:${secs.padLeft(5, '0')}';

    final newStars = starsEarned > prev.stars ? starsEarned : prev.stars;

    levelProgress[mode]![levelNum] = LevelProgress(
      completed: true,
      stars: newStars,
      bestTime: formattedTime,
      bestTimeSec: bestSec,
    );

    mazesSolved += 1;
    totalStars += (newStars - prev.stars);
    coins += coinsEarned;
    gems += gemsEarned;
    if (isPerfect) perfectRuns += 1;

    notifyListeners();
  }

  void toggleSound(bool val) {
    soundEnabled = val;
    notifyListeners();
  }

  void toggleMusic(bool val) {
    musicEnabled = val;
    notifyListeners();
  }

  void toggleHaptic(bool val) {
    hapticEnabled = val;
    notifyListeners();
  }

  void toggleDarkMode(bool val) {
    darkMode = val;
    notifyListeners();
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }
}
