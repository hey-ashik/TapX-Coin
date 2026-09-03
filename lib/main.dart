import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tap_engine_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();

  final authProvider = AuthProvider();
  await authProvider.restoreSession();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(TapXApp(authProvider: authProvider));
}

class TapXApp extends StatelessWidget {
  final AuthProvider? authProvider;

  const TapXApp({super.key, this.authProvider});

  @override
  Widget build(BuildContext context) {
    final auth = authProvider ?? AuthProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, WalletProvider, TapEngineProvider>(
          create: (context) {
            final engine = TapEngineProvider();
            final wallet = Provider.of<WalletProvider>(context, listen: false);
            final a = Provider.of<AuthProvider>(context, listen: false);
            engine.onTapsEarned = (points) => wallet.addTaps(points);
            
            a.onUserLoggedIn = (u) {
              engine.loadForUser(u.totalTaps, u.level, u.streakDays);
              wallet.loadForUser(u.totalTaps);
            };
            a.onUserLoggedOut = () {
              engine.clearSession();
              wallet.clearSession();
            };
            a.onGuestMode = () {
              engine.resetForGuest();
              wallet.resetForGuest();
            };

            if (a.isAuthenticated) {
              engine.loadForUser(a.currentUser.totalTaps, a.currentUser.level, a.currentUser.streakDays);
              wallet.loadForUser(a.currentUser.totalTaps);
            }
            return engine;
          },
          update: (context, a, wallet, engine) {
            if (engine != null) {
              engine.onTapsEarned = (points) => wallet.addTaps(points);
              a.onUserLoggedIn = (u) {
                engine.loadForUser(u.totalTaps, u.level, u.streakDays);
                wallet.loadForUser(u.totalTaps);
              };
              a.onUserLoggedOut = () {
                engine.clearSession();
                wallet.clearSession();
              };
              a.onGuestMode = () {
                engine.resetForGuest();
                wallet.resetForGuest();
              };
            }
            return engine ?? TapEngineProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authState, _) {
          return MaterialApp(
            title: 'TapX - Coin',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              reverseDuration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isMain = child.key == const ValueKey('main_scaffold');
                
                final slideAnimation = Tween<Offset>(
                  begin: isMain ? const Offset(0.0, 0.03) : const Offset(0.0, -0.03),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

                final scaleAnimation = Tween<double>(
                  begin: isMain ? 0.97 : 1.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

                final fadeAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                );

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: authState.isAuthenticated
                  ? const MainScaffoldScreen(key: ValueKey('main_scaffold'))
                  : const AuthScreen(key: ValueKey('auth_screen')),
            ),
          );
        },
      ),
    );
  }
}
