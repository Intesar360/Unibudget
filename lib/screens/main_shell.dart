import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_in.dart';
import '../widgets/profile_avatar.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation — v3 final fix.
///
/// The + button is IN the bar now, not floating above it:
/// Home | History | + | Insights | Settings, all on the
/// same bar level. The old centerFloat FAB hovered over
/// the first recent-transaction row and ate screen space;
/// this bar does neither. Lists now only need 120px bottom
/// padding (was 190px to clear the floating button).
///
/// Tabs: Home | History | (+) | Insights | Settings.
/// The + opens the Add screen — it is not a tab of its own.
///
/// IndexedStack on purpose: it keeps each tab's state alive
/// (History search + filters, scroll positions) when you
/// switch tabs.
class MainShell extends StatefulWidget {
  final TransactionStore store;
  final String displayName;
  final ProfileAvatarOption? avatar;
  final void Function(String) onDisplayNameChanged;
  final void Function(ProfileAvatarOption?) onAvatarChanged;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  final VoidCallback onLogout;

  const MainShell({
    super.key,
    required this.store,
    required this.displayName,
    required this.avatar,
    required this.onDisplayNameChanged,
    required this.onAvatarChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0 = Home, 1 = History, 2 = Insights, 3 = Settings
  int _index = 0;

  Future<void> _deleteWithConfirm(Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete transaction?'),
        content: Text('Delete "${t.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.store.delete(t.id);
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      slideFadeRoute(
        AddTransactionScreen(store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              store: widget.store,
              displayName: widget.displayName,
              avatar: widget.avatar,
              onSeeAll: () => setState(() => _index = 1),
              onEdit: (t) => openEditForm(context, widget.store, t),
              onDelete: _deleteWithConfirm,
              onOpenSettings: () => setState(() => _index = 3),
            ),
            HistoryScreen(store: widget.store),
            InsightsScreen(store: widget.store),
            // v3.3 GlobalKey fix: key Settings by theme mode.
            // Switching Dark -> Light used to reuse old
            // Material ink renderers across themes and throw
            // "A GlobalKey was used multiple times" (the red
            // block in v3.2). With this key, a theme switch
            // discards the old Settings subtree and builds a
            // fresh one, so no ink renderer can be reused.
            // Trade-off: an unsaved name typed in Settings
            // is lost if you switch theme mid-typing — rare,
            // and far better than the crash.
            SettingsScreen(
              key: ValueKey(widget.themeMode),
              store: widget.store,
              displayName: widget.displayName,
              avatar: widget.avatar,
              onDisplayNameChanged: widget.onDisplayNameChanged,
              onAvatarChanged: widget.onAvatarChanged,
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 76,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              _NavButton(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavButton(
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'History',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.royal.withOpacity(0.4),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: _openAdd,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Insights',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavButton(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.accentFor(context)
        : AppTheme.mutedFor(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: color,
                size: 22,
              ),
              SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              SizedBox(height: 3),
              AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: selected ? 6 : 0,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.accentFor(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
