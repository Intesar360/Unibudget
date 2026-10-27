import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';

/// One row, used on Home and History. Tap to expand: that is where
/// the payment method lives, plus Edit and Delete — the U and D
/// of CRUD. Keeping it in one widget means Home and History can
/// never drift apart.
///
/// v2 look: white card with a soft shadow, a tinted icon chip,
/// and the amount as a coloured pill, so income and expense are
/// readable at a glance. The amount is wrapped in a FittedBox so
/// a long amount can never push the row off the screen.
class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.isIncome;
    // v3.2 dark mode: the tile must read as a navy card, not
    // a flat black box, and its chip/pill must not be light
    // pastels. Light mode keeps the old values exactly.
    final dark = AppTheme.isDark(context);
    final amountColor = dark
        ? (isIncome ? AppTheme.darkIncomeText : AppTheme.darkExpenseText)
        : (isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed);
    final amountBg = dark
        ? (isIncome ? AppTheme.darkIncomeBg : AppTheme.darkExpenseBg)
        : (isIncome ? Color(0xFFDCFCE7) : AppTheme.expenseSoft);
    final chipBg = dark ? AppTheme.darkChip : t.category.tint;
    final chipIconColor = dark ? Colors.white : AppTheme.navy;
    final dividerColor = dark ? AppTheme.darkTileBorder : AppTheme.divider;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // v3.6 dark: old darkTile (0xFF1E2E55) with a
        // low-contrast border read as dead/bland. Now
        // the same treatment as the category chips:
        // a different dark shade of blue from the
        // background, plus a visible teal border.
        // No bright gradient. Light mode untouched.
        color: dark
            ? AppTheme.darkSurfaceVivid
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: dark
            ? Border.all(
                color: AppTheme.tealBright.withOpacity(0.45),
              )
            : null,
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      t.category.icon,
                      color: chipIconColor,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.inkFor(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${t.category.label} · ${formatDate(t.date)}',
                          style: TextStyle(
                            color: AppTheme.mutedFor(context),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: amountBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatSignedMoney(t.amount, isIncome: isIncome),
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    SizedBox(height: 12),
                    Divider(height: 1, color: dividerColor),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.paymentMethod ?? 'Cash',
                            style: TextStyle(
                              color: AppTheme.mutedFor(context),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onEdit,
                          icon: Icon(Icons.edit_outlined, size: 18),
                          label: Text('Edit'),
                        ),
                        SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: widget.onDelete,
                          icon: Icon(Icons.delete_outline, size: 18),
                          label: Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.expenseRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
