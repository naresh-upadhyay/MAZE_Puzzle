import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/achievements_screen.dart';
import 'screens/gameplay_screen.dart';
import 'screens/home_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/level_complete_overlay.dart';
import 'screens/level_select_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/world_map_screen.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF04060E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const MazeGlowApp(),
    ),
  );
}

class NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MazeGlowApp extends StatefulWidget {
  const MazeGlowApp({super.key});

  @override
  State<MazeGlowApp> createState() => _MazeGlowAppState();
}

class _MazeGlowAppState extends State<MazeGlowApp> {
  String _currentRoute = '/splash';

  int _winStars = 3;
  String _winTime = '00:24';
  int _winMoves = 15;
  int _winCoins = 50;
  int _winGems = 2;

  void _navigateTo(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  void _handleTabChanged(int index) {
    if (index == 0) _navigateTo('/world_map');
    if (index == 1) _navigateTo('/stats');
    if (index == 2) _navigateTo('/leaderboard');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAZE GLOW PATH',
      debugShowCheckedModeBanner: false,
      scrollBehavior: NoStretchScrollBehavior(),
      theme: AppTheme.darkTheme,
      home: PopScope(
        canPop: _currentRoute == '/home' || _currentRoute == '/splash',
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentRoute != '/home') {
            _navigateTo('/home');
          }
        },
        child: _buildActiveScreen(),
      ),
    );
  }

  Widget _buildActiveScreen() {
    switch (_currentRoute) {
      case '/splash':
        return SplashScreen(
          onStart: () => _navigateTo('/home'),
          onNavigate: _navigateTo,
        );
      case '/home':
        return HomeScreen(onNavigate: _navigateTo);
      case '/level_select':
        return LevelSelectScreen(
          onBack: () => _navigateTo('/home'),
          onSelectLevel: (lvl, mode) {
            final state = Provider.of<GameState>(context, listen: false);
            state.setLevel(lvl);
            state.setMode(mode);
            _navigateTo('/gameplay');
          },
        );
      case '/gameplay':
        return GameplayScreen(
          onBack: () => _navigateTo('/home'),
          onWinPayload: (stars, formattedTime, moves, coinsEarned, gemsEarned) {
            setState(() {
              _winStars = stars;
              _winTime = formattedTime;
              _winMoves = moves;
              _winCoins = coinsEarned;
              _winGems = gemsEarned;
            });
            _navigateTo('/level_complete');
          },
        );
      case '/level_complete':
        return LevelCompleteOverlay(
          onHome: () => _navigateTo('/home'),
          onNext: () {
            final state = Provider.of<GameState>(context, listen: false);
            state.setLevel(state.currentLevel + 1);
            _navigateTo('/gameplay');
          },
          starsEarned: _winStars,
          formattedTime: _winTime,
          moves: _winMoves,
          coinsEarned: _winCoins,
          gemsEarned: _winGems,
        );
      case '/world_map':
        return WorldMapScreen(
          onBack: () => _navigateTo('/home'),
          onSelectLevel: (lvl) {
            final state = Provider.of<GameState>(context, listen: false);
            state.setLevel(lvl);
            _navigateTo('/gameplay');
          },
          onTabChanged: _handleTabChanged,
        );
      case '/how_to_play':
        return HowToPlayScreen(onGotIt: () => _navigateTo('/home'));
      case '/achievements':
        return AchievementsScreen(onBack: () => _navigateTo('/home'));
      case '/settings':
        return SettingsScreen(onBack: () => _navigateTo('/home'));
      case '/stats':
        return StatsScreen(
          onBack: () => _navigateTo('/home'),
          onTabChanged: _handleTabChanged,
        );
      case '/leaderboard':
        return LeaderboardScreen(
          onBack: () => _navigateTo('/home'),
          onTabChanged: _handleTabChanged,
        );
      default:
        return HomeScreen(onNavigate: _navigateTo);
    }
  }
}
