import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int coinReward;
  int gemReward;

  AchievementItem({
    required this.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.total,
    this.claimed = false,
    this.coinReward = 100,
    this.gemReward = 5,
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
  List<String> claimedAchievements = ['first_steps'];
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

  GameState() {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      coins = prefs.getInt('coins') ?? coins;
      gems = prefs.getInt('gems') ?? gems;
      energy = prefs.getInt('energy') ?? energy;
      maxEnergy = prefs.getInt('maxEnergy') ?? maxEnergy;
      streak = prefs.getInt('streak') ?? streak;
      mazesSolved = prefs.getInt('mazesSolved') ?? mazesSolved;
      totalStars = prefs.getInt('totalStars') ?? totalStars;
      currentLevel = prefs.getInt('currentLevel') ?? currentLevel;
      selectedMode = prefs.getString('selectedMode') ?? selectedMode;
      equippedTheme = prefs.getString('equippedTheme') ?? equippedTheme;
      equippedTrail = prefs.getString('equippedTrail') ?? equippedTrail;
      undoCount = prefs.getInt('undoCount') ?? undoCount;
      hintCount = prefs.getInt('hintCount') ?? hintCount;

      soundEnabled = prefs.getBool('soundEnabled') ?? soundEnabled;
      musicEnabled = prefs.getBool('musicEnabled') ?? musicEnabled;
      hapticEnabled = prefs.getBool('hapticEnabled') ?? hapticEnabled;
      darkMode = prefs.getBool('darkMode') ?? darkMode;
      language = prefs.getString('language') ?? language;

      perfectRuns = prefs.getInt('perfectRuns') ?? perfectRuns;
      totalTimeSec = prefs.getInt('totalTimeSec') ?? totalTimeSec;
      longestStreak = prefs.getInt('longestStreak') ?? longestStreak;

      final unlockedList = prefs.getStringList('unlockedThemes');
      if (unlockedList != null) {
        unlockedThemes = unlockedList;
      }

      final claimedList = prefs.getStringList('claimedAchievements');
      if (claimedList != null) {
        claimedAchievements = claimedList;
      }

      final lpRaw = prefs.getString('levelProgressJson');
      if (lpRaw != null) {
        final decoded = jsonDecode(lpRaw) as Map<String, dynamic>;
        levelProgress = decoded.map((mode, mapData) {
          final inner = (mapData as Map<String, dynamic>).map(
            (lvlStr, val) => MapEntry(int.parse(lvlStr), LevelProgress.fromJson(val)),
          );
          return MapEntry(mode, inner);
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading prefs: $e');
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('coins', coins);
      await prefs.setInt('gems', gems);
      await prefs.setInt('energy', energy);
      await prefs.setInt('maxEnergy', maxEnergy);
      await prefs.setInt('streak', streak);
      await prefs.setInt('mazesSolved', mazesSolved);
      await prefs.setInt('totalStars', totalStars);
      await prefs.setInt('currentLevel', currentLevel);
      await prefs.setString('selectedMode', selectedMode);
      await prefs.setString('equippedTheme', equippedTheme);
      await prefs.setString('equippedTrail', equippedTrail);
      await prefs.setInt('undoCount', undoCount);
      await prefs.setInt('hintCount', hintCount);

      await prefs.setBool('soundEnabled', soundEnabled);
      await prefs.setBool('musicEnabled', musicEnabled);
      await prefs.setBool('hapticEnabled', hapticEnabled);
      await prefs.setBool('darkMode', darkMode);
      await prefs.setString('language', language);

      await prefs.setInt('perfectRuns', perfectRuns);
      await prefs.setInt('totalTimeSec', totalTimeSec);
      await prefs.setInt('longestStreak', longestStreak);

      await prefs.setStringList('unlockedThemes', unlockedThemes);
      await prefs.setStringList('claimedAchievements', claimedAchievements);

      final lpMap = levelProgress.map((mode, innerMap) {
        final innerJson = innerMap.map((lvl, lp) => MapEntry(lvl.toString(), lp.toJson()));
        return MapEntry(mode, innerJson);
      });
      await prefs.setString('levelProgressJson', jsonEncode(lpMap));
    } catch (e) {
      debugPrint('Error saving prefs: $e');
    }
  }

  void setMode(String mode) {
    selectedMode = mode;
    notifyListeners();
    _savePrefs();
  }

  void setLevel(int lvl) {
    currentLevel = lvl;
    notifyListeners();
    _savePrefs();
  }

  void addCoins(int amount) {
    coins += amount;
    notifyListeners();
    _savePrefs();
  }

  void addGems(int amount) {
    gems += amount;
    notifyListeners();
    _savePrefs();
  }

  void refillEnergy() {
    energy = maxEnergy;
    notifyListeners();
    _savePrefs();
  }

  bool useUndo() {
    if (undoCount > 0) {
      undoCount--;
      notifyListeners();
      _savePrefs();
      return true;
    }
    return false;
  }

  bool useHint() {
    if (hintCount > 0) {
      hintCount--;
      notifyListeners();
      _savePrefs();
      return true;
    }
    return false;
  }

  bool buyAndEquipTheme(String themeId, int gemPrice) {
    if (unlockedThemes.contains(themeId)) {
      equippedTheme = themeId;
      notifyListeners();
      _savePrefs();
      return true;
    }
    if (gems >= gemPrice) {
      gems -= gemPrice;
      unlockedThemes.add(themeId);
      equippedTheme = themeId;
      notifyListeners();
      _savePrefs();
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
    _savePrefs();
  }

  void claimAchievement(String key, int coinReward, int gemReward) {
    if (!claimedAchievements.contains(key)) {
      claimedAchievements.add(key);
      coins += coinReward;
      gems += gemReward;
      notifyListeners();
      _savePrefs();
    }
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
    totalTimeSec += timeSec.round();
    if (isPerfect) perfectRuns += 1;

    notifyListeners();
    _savePrefs();
  }

  void toggleSound(bool val) {
    soundEnabled = val;
    notifyListeners();
    _savePrefs();
  }

  void toggleMusic(bool val) {
    musicEnabled = val;
    notifyListeners();
    _savePrefs();
  }

  void toggleHaptic(bool val) {
    hapticEnabled = val;
    notifyListeners();
    _savePrefs();
  }

  void toggleDarkMode(bool val) {
    darkMode = val;
    notifyListeners();
    _savePrefs();
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
    _savePrefs();
  }
}

