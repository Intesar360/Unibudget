import 'package:flutter/material.dart';

import 'repositories/transaction_repository.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/profile_avatar.dart';

void main() {
  runApp(const UniBudgetApp());
}

/// v3.8 TEST BUILD: ApiTransactionRepository (friend's
/// Django backend) instead of the Phase 2 mock data.
/// v3.7 with MockTransactionRepository is still the safe
/// Phase 2 build — keep it until this test build proves
/// out on the phone. No screen changes needed: screens
/// still talk only to TransactionStore.
///
/// Auth and theme state live here (not in a screen) so that:
/// - the app starts on Login, and only shows MainShell after
///   onAuthenticated fires (see login_screen.dart for the Phase 3 plan);
/// - the Settings tab can change the whole app's theme, and can
///   log out, returning the user to Login.
class UniBudgetApp extends StatefulWidget {
  const UniBudgetApp({super.key});

  @override
  State<UniBudgetApp> createState() => _UniBudgetAppState();
}

class _UniBudgetAppState extends State<UniBudgetApp> {
  late final TransactionStore _store;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAuthenticated = false;
  String _displayName = 'Intesar';
  ProfileAvatarOption? _avatar;

  @override
  void initState() {
    super.initState();
    _store = TransactionStore(ApiTransactionRepository());
    // No token yet, so this loads [] and stays on Login.
    // Real data loads in onAuthenticated, after login.
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBudget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _isAuthenticated
          ? MainShell(
              store: _store,
              displayName: _displayName,
              avatar: _avatar,
              onDisplayNameChanged: (name) =>
                  setState(() => _displayName = name),
              onAvatarChanged: (avatar) =>
                  setState(() => _avatar = avatar),
              themeMode: _themeMode,
              onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
              onLogout: () {
                ApiService.clearTokens();
                _store.resetToEmpty();
                setState(() {
                  _isAuthenticated = false;
                  _avatar = null;
                });
              },
            )
          : LoginScreen(
              onAuthenticated: (displayName) {
                // Clear the previous session, then load
                // this user's real transactions from Django.
                _store.resetToEmpty();
                setState(() {
                  _displayName = displayName;
                  _avatar = null;
                  _isAuthenticated = true;
                });
                _store.load();
              },
            ),
    );
  }
}
