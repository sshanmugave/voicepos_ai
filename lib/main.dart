import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appState});

  final AppState appState;

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB85C38),
    brightness: Brightness.light,
    surface: const Color(0xFFF7F1EA),
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB85C38),
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final isDark = state.isDarkMode;
          final colorScheme = isDark ? _darkScheme : _lightScheme;

          return MaterialApp(
            title: 'VoicePOS AI',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: colorScheme,
              scaffoldBackgroundColor:
                  isDark ? null : const Color(0xFFF4EFE8),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: isDark ? null : Colors.white,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor:
                    isDark ? null : const Color(0xFFF4EFE8),
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
                centerTitle: false,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: isDark ? null : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            routes: {
              '/': (_) {
                if (!state.isInitialized) {
                  return const _SplashScreen();
                }

                if (!state.isLanguageSelected) {
                  return const LanguageSelectionScreen();
                }

                if (!state.isLoggedIn) {
                  return const AuthScreen();
                }

                return state.shopName.isEmpty
                    ? const LoginScreen()
                    : const HomeScreen();
              },
            },
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'SB',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Smart Billing',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
