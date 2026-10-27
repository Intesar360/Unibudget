import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/animated_in.dart';

/// Insights: computed from the same transaction list — no new
/// table, no new endpoint, no new model. If a transaction is
/// added, edited or deleted, every number and bar on this
/// screen moves with it, because it all reads TransactionStore.
///
/// v2 fixes, directly from the phone screenshot:
/// 1. RIGHT OVERFLOWED BY 35 PIXELS — the old legend was a
///    single Row: Income dot + Expense dot + the long text
///    "Right number = month net". On a narrow phone that Row
///    was wider than the screen. It is now a Wrap, and the
///    explanation is a separate caption line underneath.
/// 2. BOTTOM OVERFLOWED BY 3.0 PIXELS — the old bottom bar
///    had no fixed height and its labels were squeezed. The
///    new bottom bar in main_shell.dart is a fixed-height
///    SafeArea container, and this list has 190px bottom
///    padding so nothing sits under it.
/// 3. Month rows are rebuilt as cards: month + net on one
///    header row (both FittedBox, so a long amount shrinks
///    instead of overflowing), then Income and Expense bars
///    on their own full-width rows with their own values.
///    No fixed 92px + 84px row can overflow any more, because
///    every bar is Expanded and every amount is FittedBox.
class InsightsScreen extends StatelessWidget {
  final TransactionStore store;

  const InsightsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final transactions = store.all;
        final income = store.totalIncome;
        final expense = store.totalExpense;
        final saved = income - expense;
        final savingsRate = income > 0 ? (saved / income * 100) : 0.0;

        final expenses = transactions.where((t) => !t.isIncome).toList();
        Transaction? biggestExpense;
        if (expenses.isNotEmpty) {
          biggestExpense = expenses.reduce(
            (a, b) => a.amount >= b.amount ? a : b,
          );
        }

        final spending = store.spendingByCategory;
        final spendingEntries = spending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final grouped = store.groupedByMonth;
        double maxMonthValue = 0;
        final monthStats = <DateTime, ({double income, double expense})>{};
        for (final entry in grouped.entries) {
          final monthIncome = entry.value
              .where((t) => t.isIncome)
              .fold(0.0, (sum, t) => sum + t.amount);
          final monthExpense = entry.value
              .where((t) => !t.isIncome)
              .fold(0.0, (sum, t) => sum + t.amount);
          monthStats[entry.key] =
              (income: monthIncome, expense: monthExpense);
          if (monthIncome > maxMonthValue) maxMonthValue = monthIncome;
          if (monthExpense > maxMonthValue) maxMonthValue = monthExpense;
        }
        if (maxMonthValue == 0) maxMonthValue = 1;

        return ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'Insights',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.inkFor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Computed from your transactions — nothing extra to enter.',
              style: TextStyle(color: AppTheme.mutedFor(context)),
            ),
            SizedBox(height: 18),
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Saved',
                      value: formatMoney(saved),
                      sub: income > 0
                          ? '${savingsRate.toStringAsFixed(0)}% of income'
                          : 'No income yet',
                      gradient: AppTheme.buttonGradient,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Biggest expense',
                      value: biggestExpense == null
                          ? '—'
                          : formatMoney(biggestExpense.amount),
                      sub: biggestExpense?.title ?? 'No expenses yet',
                      gradient: LinearGradient(
                        colors: [AppTheme.navy, AppTheme.navySoft],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),
            Text(
              'Income vs expense by month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkFor(context),
              ),
            ),
            SizedBox(height: 12),
            if (monthStats.isEmpty)
              Text('Add a transaction to see your months here.')
            else
              for (var mi = 0; mi < monthStats.keys.length; mi++) ...[
                FadeSlideIn(
                  delay: Duration(milliseconds: 80 + mi * 80),
                  child: _MonthCard(
                    month: monthStats.keys.elementAt(mi),
                    income: monthStats.values.elementAt(mi).income,
                    expense: monthStats.values.elementAt(mi).expense,
                    maxValue: maxMonthValue,
                    net: store.monthNet(
                      grouped[monthStats.keys.elementAt(mi)]!,
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],
            // Legend — Wrap, never a single Row. This was the
            // 35px overflow. The explanation is a caption below.
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendDot(color: AppTheme.incomeGreen, label: 'Income'),
                _LegendDot(color: AppTheme.expenseRed, label: 'Expense'),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'The number on each month card is that month\'s net.',
              style: TextStyle(color: AppTheme.mutedFor(context), fontSize: 13),
            ),
            SizedBox(height: 28),
            Text(
              'Where the money goes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.inkFor(context),
              ),
            ),
            SizedBox(height: 12),
            if (spendingEntries.isEmpty)
              Text('No expenses yet.')
            else
              for (var i = 0; i < spendingEntries.length; i++) ...[
                FadeSlideIn(
                  delay: Duration(milliseconds: 80 + i * 60),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                spendingEntries[i].key.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${formatMoney(spendingEntries[i].value)} · '
                                '${(spendingEntries[i].value / expense * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: AppTheme.mutedFor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedBar(
                            fraction: expense > 0
                                ? spendingEntries[i].value / expense
                                : 0,
                            color: AppTheme.barColor(i),
                            height: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final double income;
  final double expense;
  final double maxValue;
  final double net;

  const _MonthCard({
    required this.month,
    required this.income,
    required this.expense,
    required this.maxValue,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthYear(month),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(net),
                  style: TextStyle(
                    color: net >= 0
                        ? AppTheme.incomeGreen
                        : AppTheme.expenseRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _MonthBarRow(
            label: 'Income',
            value: income,
            fraction: income / maxValue,
            color: AppTheme.incomeGreen,
          ),
          SizedBox(height: 8),
          _MonthBarRow(
            label: 'Expense',
            value: expense,
            fraction: expense / maxValue,
            color: AppTheme.expenseRed,
          ),
        ],
      ),
    );
  }
}

class _MonthBarRow extends StatelessWidget {
  final String label;
  final double value;
  final double fraction;
  final Color color;

  const _MonthBarRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedFor(context),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBar(fraction: fraction, color: color, height: 10),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatMoney(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
          SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
