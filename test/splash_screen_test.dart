import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maze_glow_path/models/game_state.dart';
import 'package:maze_glow_path/screens/splash_screen.dart';
import 'package:maze_glow_path/theme/app_theme.dart';

void main() {
  testWidgets('SplashScreen renders with all graphical animations and triggers callbacks',
      (WidgetTester tester) async {
    bool started = false;
    String? navigatedRoute;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameState(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: SplashScreen(
            onStart: () => started = true,
            onNavigate: (route) => navigatedRoute = route,
          ),
        ),
      ),
    );

    // Initial pump
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance animations through entrance timeline
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify Title and Subtitle exist
    expect(find.text('MAZE'), findsOneWidget);
    expect(find.text('GLOW PATH'), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap the Start button
    await tester.tap(find.text('TAP TO START'));
    await tester.pump();

    expect(started, isTrue);

    // Tap Achievements footer button
    await tester.tap(find.text('Achievements'));
    await tester.pump();
    expect(navigatedRoute, equals('/achievements'));
  });
}
