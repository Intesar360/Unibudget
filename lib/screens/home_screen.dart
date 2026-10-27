import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/animated_in.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

/// Home: balance, income vs expense, spending by category,
/// recent list. Every number here is computed in
/// TransactionStore from the same list History shows —
/// nothing is typed in by hand on this screen.
///
/// v2 look: gradient balance card with decorative circles,
/// animated counting balance, income/expense pills, animated
/// category segments, and staggered recent rows. The card
/// header is a greeting + a profile initial, not a plain
/// title — it feels like a personal app, not a form.
class HomeScreen extends StatelessWidget {
  final TransactionStore store;
  final String displayName;
  final ProfileAvatarOption? avatar;
  final VoidCallback onSeeAll;
  final void Function(Transaction) onEdit;
  final void Function(Transaction) onDelete;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.store,
    required this.displayName,
    required this.avatar,
    required this.onSeeAll,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final spending = store.spendingByCategory;
        final totalSpent = spending.values.fold(0.0, (a, b) => a + b);
        final entries = spending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good to see you,',
                          style: TextStyle(color: AppTheme.mutedFor(context)),
                        ),
                        Text(
                          'Hi, $displayName',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.inkFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onOpenSettings,
                    child: ProfileAvatar(
                      avatar: avatar,
                      displayName: displayName,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Balance card — gradient, not flat navy.
            FadeSlideIn(
              delay: Duration(milliseconds: 80),
              child: Container(
                padding: EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.balanceGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.royal.withOpacity(0.35),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'CURRENT BALANCE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        AnimatedMoney(
                          value: store.balance,
                          format: formatMoney,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _BalancePill(
                                icon: Icons.trending_up,
                                label: 'Income',
                                value: formatSignedMoney(
                                  store.totalIncome,
                                  isIncome: true,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _BalancePill(
                                icon: Icons.trending_down,
                                label: 'Expense',
                                value: formatSignedMoney(
                                  store.totalExpense,
                                  isIncome: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Spending by category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkFor(context),
              ),
            ),
            SizedBox(height: 12),
            if (totalSpent > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Expanded(
                        flex: (entries[i].value * 100)
                            .round()
                            .clamp(1, 10000),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 600 + i * 120,
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) {
                            return Opacity(
                              opacity: t,
                              child: Container(
                                height: 12,
                                color: AppTheme.barColor(i),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // v3.6 dark: chips were cardColor
                        // (0xFF16203A) with no border, so
                        // they read as black on navyDeep.
                        // Now a different dark blue plus
                        // a visible teal border, exactly
                        // like the chips the user liked.
                        // Light mode keeps cardColor.
                        color: AppTheme.isDark(context)
                            ? AppTheme.darkSurfaceVivid
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: AppTheme.isDark(context)
                            ? Border.all(
                                color: AppTheme.tealBright
                                    .withOpacity(0.55),
                              )
                            : null,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.barColor(i),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${entries[i].key.label} '
                            '${formatMoney(entries[i].value)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else
              Text('No expenses yet. Add your first one with +.'),
            SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkFor(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See all →',
                    style: TextStyle(
                      color: AppTheme.accentFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (store.recent.isEmpty)
              Text('No transactions yet. Tap + to add your first one.', style: TextStyle(color: AppTheme.mutedFor(context)))
            else
              for (var i = 0; i < store.recent.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 120 + i * 70),
                  child: TransactionTile(
                    transaction: store.recent[i],
                    onEdit: () => onEdit(store.recent[i]),
                    onDelete: () => onDelete(store.recent[i]),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _BalancePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BalancePill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper used by MainShell so Home's tiles can open the edit form.
Future<void> openEditForm(
  BuildContext context,
  TransactionStore store,
  Transaction transaction,
) async {
  await Navigator.of(context).push(
    slideFadeRoute(
      AddTransactionScreen(store: store, existing: transaction),
    ),
  );
}
