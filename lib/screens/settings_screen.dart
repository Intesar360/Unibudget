import 'package:flutter/material.dart';

import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_in.dart';
import '../widgets/profile_avatar.dart';

/// Settings: local only, except for the login gate itself.
///
/// v3.2 changes:
/// - D2: the "Your data" section is GONE entirely — the user
///   called it unnecessary. Settings is now: header, Profile,
///   Appearance, About, Log out.
/// - D3: About is no longer a paragraph. It is a card in the
///   app's card style, with the same facts as separate
///   icon rows (App / Course / Frontend / Backend / Database).
/// - F1: Profile lets the user edit their display name.
///   Home greets by email prefix after Login because Login
///   has no name to use; editing here replaces that greeting
///   (and the profile initial) for the rest of the session.
///   Phase 2 has no backend user table, so an edited name
///   lives for that login session — logging in again starts
///   from the login/sign-up name again. Phase 3 will store
///   the name per user in Django.
/// - F2: Profile also has the avatar picker. Tapping an
///   avatar only PREVIEWS it (ring + larger preview); it is
///   not applied until Apply is tapped, and Cancel restores
///   the currently applied avatar. If no avatar is ever
///   applied, Home keeps showing the initial, as before.
///   Same Phase 2 session limit as the name: Phase 3 will
///   store the avatar per user.
///
/// v3.3 changes:
/// - The avatar grid is NO LONGER always visible in
///   Settings — the user called it distracting. Profile now
///   has a single "Change avatar" button; tapping it opens
///   a picker dialog with the grid, preview, Apply and
///   Cancel. Closing the dialog removes the grid from the
///   tree entirely.
/// - Avatar gradients are theme-matched (see
///   profile_avatar.dart): navy / royal / blue / teal only.
/// - GlobalKey crash fix: MainShell now gives Settings a
///   key based on the current theme mode, so switching
///   Dark -> Light rebuilds Settings from scratch instead
///   of reusing old Material ink renderers across themes.
///   That duplicate "ink renderer" GlobalKey was the red
///   block the user saw on a theme switch in v3.2. Dialog
///   grid items also carry ValueKeys by avatar label, so
///   no two items can share a widget identity.
///
/// Appearance (System / Light / Dark) actually changes the
/// whole app theme, via the callback to MaterialApp. Logout
/// returns to the Login page.
class SettingsScreen extends StatefulWidget {
  final TransactionStore store;
  final String displayName;
  final ProfileAvatarOption? avatar;
  final void Function(String) onDisplayNameChanged;
  final void Function(ProfileAvatarOption?) onAvatarChanged;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  late String _syncedDisplayName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
    _syncedDisplayName = widget.displayName;
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only resync when the parent's value actually changed
    // (e.g. a fresh login). A rebuild with the same value
    // must NOT wipe an unsaved name the user is still
    // typing. Note: MainShell keys Settings by theme mode,
    // so a theme switch creates a fresh state anyway —
    // that is deliberate, it is the GlobalKey crash fix.
    if (widget.displayName != _syncedDisplayName) {
      _syncedDisplayName = widget.displayName;
      _nameController.text = widget.displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name can't be empty.")),
      );
      _nameController.text = widget.displayName;
      return;
    }
    widget.onDisplayNameChanged(name);
    _syncedDisplayName = name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Name updated to $name.')),
    );
  }

  /// Avatar picker dialog: grid is only mounted while this
  /// dialog is open, never in the Settings list itself.
  /// Tap an avatar to preview it (ring), Apply to set it,
  /// Cancel (or tapping outside) to keep the current one,
  /// "Use my initial instead" to clear back to the initial.
  /// The dialog applies directly via onAvatarChanged, so
  /// its return value never needs to distinguish Cancel
  /// from Initial from a tap-outside dismiss.
  ///
  /// v3.7 fix: the old version used GridView.builder
  /// inside the dialog. In debug mode that threw
  /// repeated semantics assertions
  /// ('!childSemantics.renderObject._needsLayout' /
  /// '!semantics.parentDataDirty') and the dialog
  /// sometimes never appeared at all on tap. Replaced
  /// with a plain Wrap of fixed-size circles — no
  /// slivers, no builder, no keys — so the dialog
  /// opens reliably. Flow is unchanged: tap to
  /// preview, Apply to set.
  Future<void> _showAvatarPicker() async {
    ProfileAvatarOption? preview = widget.avatar;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Choose an avatar'),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final option in avatarOptions)
                      GestureDetector(
                        onTap: () => setDialogState(
                          () => preview = option,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: option.gradient,
                            shape: BoxShape.circle,
                            border: preview == option
                                ? Border.all(
                                    color: AppTheme.tealBright,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Center(
                            child: Text(
                              option.emoji,
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    widget.onAvatarChanged(null);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Avatar cleared.')),
                    );
                  },
                  child: Text('Use my initial instead'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onAvatarChanged(preview);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          preview == null
                              ? 'Avatar cleared.'
                              : '${preview!.label} avatar applied.',
                        ),
                      ),
                    );
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    final dark = AppTheme.isDark(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: dark ? AppTheme.darkChip : Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: dark ? Colors.white : AppTheme.navy,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.inkFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return ListView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        FadeSlideIn(
          child: Container(
            padding: EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.balanceGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Make UniBudget yours.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        // Profile — F1 name edit + F2 avatar picker.
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkFor(context),
          ),
        ),
        SizedBox(height: 10),
        FadeSlideIn(
          delay: Duration(milliseconds: 40),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileAvatar(
                      avatar: widget.avatar,
                      displayName: widget.displayName,
                      size: 56,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.avatar == null
                                ? 'Your initial'
                                : widget.avatar!.label,
                            style: TextStyle(
                              color: AppTheme.inkFor(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your avatar, if you picked one. '
                            'Otherwise your initial.',
                            style: TextStyle(
                              color: AppTheme.mutedFor(context),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Display name',
                  style: TextStyle(
                    color: AppTheme.mutedFor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saveName,
                    child: Text('Save name'),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAvatarPicker,
                    icon: Icon(Icons.face_outlined),
                    label: Text('Change avatar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkFor(context),
          ),
        ),
        SizedBox(height: 10),
        FadeSlideIn(
          delay: Duration(milliseconds: 80),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android_outlined, size: 18),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 18),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 18),
                label: Text('Dark'),
              ),
            ],
            selected: {widget.themeMode},
            onSelectionChanged: (selection) {
              widget.onThemeModeChanged(selection.first);
            },
          ),
        ),
        SizedBox(height: 24),
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.inkFor(context),
          ),
        ),
        SizedBox(height: 10),
        FadeSlideIn(
          delay: Duration(milliseconds: 140),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _aboutRow(
                  Icons.account_balance_wallet_outlined,
                  'App',
                  'UniBudget — a student expense tracker',
                ),
                Divider(
                  height: 28,
                  color: dark ? AppTheme.darkTileBorder : AppTheme.divider,
                ),
                _aboutRow(
                  Icons.school_outlined,
                  'Course',
                  'CSE 464',
                ),
                Divider(
                  height: 28,
                  color: dark ? AppTheme.darkTileBorder : AppTheme.divider,
                ),
                _aboutRow(
                  Icons.smartphone_outlined,
                  'Frontend',
                  'Flutter',
                ),
                Divider(
                  height: 28,
                  color: dark ? AppTheme.darkTileBorder : AppTheme.divider,
                ),
                _aboutRow(
                  Icons.dns_outlined,
                  'Backend',
                  'Django REST Framework',
                ),
                Divider(
                  height: 28,
                  color: dark ? AppTheme.darkTileBorder : AppTheme.divider,
                ),
                _aboutRow(
                  Icons.storage_outlined,
                  'Database',
                  'SQLite',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Log out?'),
                content: Text(
                  'You will return to the Login page.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text('Log out'),
                  ),
                ],
              ),
            );
            if (confirmed == true) widget.onLogout();
          },
          icon: Icon(Icons.logout_outlined),
          label: Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.expenseRed,
            minimumSize: Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
