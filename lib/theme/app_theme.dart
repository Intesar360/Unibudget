import 'package:flutter/material.dart';

/// UniBudget design system — v3 final fix (Oct 2026).
///
/// Palette taken from the user's own logo: white tile, big U in
/// navy / royal blue / teal, bright blue coin with a white ৳,
/// small chart bars. No yellow, no mint, no green-heavy theme
/// any more — the brand is blue/teal. Green is kept ONLY as
/// "money in" and red ONLY as "money out", never as a theme
/// colour, so income/expense still read at a glance.
///
/// Dark mode (v3, the main fix here): screens must NOT hard-code
/// the light ink/muted colours. Use inkFor(context) and
/// mutedFor(context) for every heading, subtitle and label.
/// Those two helpers return white / light grey in dark mode
/// and dark ink / slate in light mode. Cards and scaffolds
/// already come from Theme.of(context).cardColor and the
/// theme's scaffoldBackgroundColor, so they follow the mode
/// automatically. A heading that still uses the old constants
/// will be invisible in dark mode — that was the bug.
///
/// Other v3 rules:
/// - No custom pageTransitionsTheme: the iOS builder is not
///   available from the material import alone and broke the
///   debug build (app_theme.dart:171 in v2).
/// - Input fields never use a floating label: the theme sets
///   floatingLabelBehavior to never, so a label can never sit
///   half in / half out of a field's border. Login and Add
///   use a small label above the field plus hint text inside.
/// - No fixed-width Row that can overflow on a narrow phone:
///   every horizontal row uses Expanded / Flexible / Wrap /
///   FittedBox.
class AppTheme {
  // Brand — from the user's logo.
  static const navy = Color(0xFF0D2348);
  static const navyDeep = Color(0xFF081426);
  static const navySoft = Color(0xFF16305E);
  static const royal = Color(0xFF2456D6);
  static const blue = Color(0xFF1E90E8);
  static const teal = Color(0xFF1F7A8C);
  static const tealBright = Color(0xFF2EA8C2);
  static const tile = Color(0xFFD5F1FD);
  // Kept only for income/expense meaning, not for theming.
  static const green = Color(0xFF10B981);
  static const incomeGreen = Color(0xFF059669);
  static const expenseRed = Color(0xFFE11D48);
  static const expenseSoft = Color(0xFFFFE4E6);

  // Surfaces / text — light mode values. For dark mode, use
  // the helpers below, never these constants directly in a
  // heading or body text.
  static const background = Color(0xFFF2F7FA);
  static const surface = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
  static const darkCard = Color(0xFF16203A);
  static const darkMuted = Color(0xFF94A3B8);

  // v3.2 dark-mode transaction tiles: the old tile used the
  // plain dark card (which read as a flat black box) plus
  // light pastel chips/pills. These are the dark versions —
  // a visibly navy card, a navy chip, and dark-tinted pills
  // with bright text. Light mode keeps its old pastels and
  // is untouched by these constants.
  static const darkTile = Color(0xFF1E2E55);
  static const darkTileBorder = Color(0xFF2A3B5C);
  // v3.6 dark mode, user-chosen (2026-10-26): transaction
  // cards and category chips must look like the
  // Food/Transport chips in the bright preview — a
  // different dark shade of blue from the near-black
  // navyDeep background, plus a visible border, NOT a
  // bright gradient. This shade is clearly lighter
  // than navyDeep (0xFF081426) and darkCard
  // (0xFF16203A), but still dark blue, not bright.
  // The border is tealBright at the call site, so it
  // reads like the chips. Light mode is untouched.
  // v3.7: user asked for a bit darker than v3.6's
  // 0xFF23406F, so this is 0xFF1B3258 — still clearly
  // distinct from navyDeep (0xFF081426) and darkCard
  // (0xFF16203A), with the teal border keeping it
  // visible, but less bright than v3.6.
  static const darkSurfaceVivid = Color(0xFF1B3258);
  static const darkChip = Color(0xFF24365E);
  static const darkIncomeBg = Color(0xFF123A2E);
  static const darkIncomeText = Color(0xFF4ADE80);
  static const darkExpenseBg = Color(0xFF3F1622);
  static const darkExpenseText = Color(0xFFF87171);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color inkFor(BuildContext context) =>
      isDark(context) ? Colors.white : ink;

  static Color mutedFor(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color cardFor(BuildContext context) =>
      isDark(context) ? darkCard : surface;

  static Color accentFor(BuildContext context) =>
      isDark(context) ? tealBright : royal;

  static const balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2348), Color(0xFF2456D6), Color(0xFF1F7A8C)],
  );

  static const loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF081426),
      Color(0xFF0D2348),
      Color(0xFF2456D6),
      Color(0xFF1F7A8C),
    ],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2456D6), Color(0xFF1F7A8C)],
  );

  static const _barColors = [
    Color(0xFF0D2348),
    Color(0xFF2456D6),
    Color(0xFF1F7A8C),
    Color(0xFF1E90E8),
    Color(0xFF64748B),
    Color(0xFF0891B2),
  ];

  static Color barColor(int index) => _barColors[index % _barColors.length];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0D2348).withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royal,
          primary: royal,
          secondary: teal,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          foregroundColor: ink,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: royal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: royal, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          selectedColor: royal,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royal,
          brightness: Brightness.dark,
          primary: tealBright,
          secondary: blue,
        ),
        scaffoldBackgroundColor: navyDeep,
        appBarTheme: const AppBarTheme(
          backgroundColor: navyDeep,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: royal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCard,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A3B5C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: blue, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          selectedColor: royal,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
}

/// A primary button with the royal -> teal gradient.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.royal.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
