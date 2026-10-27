import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/animated_in.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

/// History: the R of CRUD, plus Edit / Delete from each
/// expanded row. Filters are search + type + category — all
/// three just narrow the same list, so they cost nothing
/// on the backend.
///
/// v2: search sits in a white card, chips are pill-shaped
/// with a teal selected state, and each month is a section
/// header with its computed net on the right (FittedBox, so
/// it can never overflow).
class HistoryScreen extends StatefulWidget {
  final TransactionStore store;

  const HistoryScreen({super.key, required this.store});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  TransactionType? _filter; // null = All
  Category? _categoryFilter; // null = All categories

  Future<void> _confirmDelete(Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete transaction?'),
        content: Text('Delete "${t.title}" (${formatMoney(t.amount)})?'),
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

  Future<void> _edit(Transaction t) async {
    await Navigator.of(context).push(
      slideFadeRoute(
        AddTransactionScreen(store: widget.store, existing: t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        var items = widget.store.all;
        if (_filter != null) {
          items = items.where((t) => t.type == _filter).toList();
        }
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          items = items.where((t) {
            return t.title.toLowerCase().contains(q) ||
                t.category.label.toLowerCase().contains(q);
          }).toList();
        }
        final availableCategories =
            items.map((t) => t.category).toSet().toList()
              ..sort((a, b) => a.label.compareTo(b.label));
        if (_categoryFilter != null) {
          items = items.where((t) => t.category == _categoryFilter).toList();
        }
        final grouped = <DateTime, List<Transaction>>{};
        for (final t in items) {
          grouped.putIfAbsent(
            DateTime(t.date.year, t.date.month),
            () => [],
          ).add(t);
        }
        final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'History',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.inkFor(context),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap a transaction to see, edit or delete it.',
              style: TextStyle(color: AppTheme.mutedFor(context)),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                boxShadow: AppTheme.cardShadow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search transactions',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() {
                    _filter = null;
                    _categoryFilter = null;
                  }),
                ),
                _FilterChip(
                  label: 'Income',
                  selected: _filter == TransactionType.income,
                  onTap: () => setState(() {
                    _filter = TransactionType.income;
                    _categoryFilter = null;
                  }),
                ),
                _FilterChip(
                  label: 'Expenses',
                  selected: _filter == TransactionType.expense,
                  onTap: () => setState(() {
                    _filter = TransactionType.expense;
                    _categoryFilter = null;
                  }),
                ),
              ],
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All categories',
                    selected: _categoryFilter == null,
                    onTap: () => setState(() => _categoryFilter = null),
                  ),
                  SizedBox(width: 8),
                  for (final c in availableCategories) ...[
                    _FilterChip(
                      label: c.label,
                      selected: _categoryFilter == c,
                      onTap: () => setState(() => _categoryFilter = c),
                    ),
                    SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),
            if (items.isEmpty)
              Text(widget.store.all.isEmpty ? 'No transactions yet. Tap + to add your first one.' : 'No transactions match. Try clearing the search.', style: TextStyle(color: AppTheme.mutedFor(context)))
            else
              for (final month in months) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatMonthYear(month),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkFor(context),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMoney(widget.store.monthNet(grouped[month]!)),
                        style: TextStyle(
                          color: AppTheme.mutedFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                for (var i = 0; i < grouped[month]!.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 60 + i * 50),
                    child: TransactionTile(
                      transaction: grouped[month]![i],
                      onEdit: () => _edit(grouped[month]![i]),
                      onDelete: () => _confirmDelete(grouped[month]![i]),
                    ),
                  ),
                SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentFor(context) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? null : AppTheme.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.inkFor(context),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
