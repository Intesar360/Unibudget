import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/animated_in.dart';

/// Add / Edit — the C and U of CRUD.
///
/// v2: the amount is a gradient hero card that animates
/// when the number changes, the Income/Expense toggle is
/// a segmented control, and categories are icon chips in
/// a white card. Behaviour is unchanged from v1:
///
/// 1. No custom on-screen keypad. It ate half the screen
///    and duplicated the phone keyboard.
/// 2. Category chips change with Income / Expense, and
///    the selected category resets when you switch type.
/// 3. Edit reuses this exact screen (pass [existing]).
class AddTransactionScreen extends StatefulWidget {
  final TransactionStore store;
  final Transaction? existing; // null = add, set = edit

  const AddTransactionScreen({
    super.key,
    required this.store,
    this.existing,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late TransactionType _type;
  late Category _category;
  late DateTime _date;
  String _paymentMethod = 'Cash';

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(2),
    );
    _type = e?.type ?? TransactionType.expense;
    _category = e?.category ??
        (_type == TransactionType.income
            ? Category.salary
            : Category.food);
    _date = e?.date ?? DateTime.now();
    if (e != null) _paymentMethod = e.paymentMethod ?? 'Cash';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<Category> get _categories =>
      _type == TransactionType.income ? incomeCategories : expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    // v3.8: with the API, a save can fail (no network,
    // expired token, backend 400). Show that instead of
    // crashing / silently doing nothing, and stay on
    // the form so the user can retry.
    try {
      if (_isEditing) {
        await widget.store.update(
          widget.existing!.copyWith(
            title: _titleController.text.trim(),
            amount: amount,
            type: _type,
            category: _category,
            date: _date,
            paymentMethod: _paymentMethod,
          ),
        );
      } else {
        await widget.store.add(
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            amount: amount,
            type: _type,
            category: _category,
            date: _date,
            paymentMethod: _paymentMethod,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = double.tryParse(_amountController.text) ?? 0;
    final isIncome = _type == TransactionType.income;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // Amount hero — animates on every keystroke.
            FadeSlideIn(
              child: Container(
                padding: EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: isIncome
                      ? AppTheme.buttonGradient
                      : LinearGradient(
                          colors: [AppTheme.navy, AppTheme.navySoft],
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      _isEditing
                          ? 'Editing this transaction'
                          : 'How much is this?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: FittedBox(
                        key: ValueKey(formatMoney(preview)),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatMoney(preview),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isIncome ? 'Money in' : 'Money out',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.income,
                  icon: Icon(Icons.trending_up, size: 18),
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: Icon(Icons.trending_down, size: 18),
                  label: Text('Expense'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _category = _type == TransactionType.income
                      ? Category.salary
                      : Category.food;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount (৳)',
                prefixText: '৳ ',
              ),
              validator: (v) {
                final amount = double.tryParse(v?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than 0';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Transaction name',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: Icon(Icons.calendar_today_outlined, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatDate(_date)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Payment method',
                    ),
                    items: [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bKash', child: Text('bKash')),
                      DropdownMenuItem(
                        value: 'Debit card •• 1842',
                        child: Text('Debit card •• 1842'),
                      ),
                      DropdownMenuItem(
                        value: 'Bank transfer',
                        child: Text('Bank transfer'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'Cash'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _categories)
                        ChoiceChip(
                          label: Text(c.label),
                          avatar: Icon(c.icon, size: 18),
                          selected: _category == c,
                          selectedColor: AppTheme.accentFor(context),
                          labelStyle: TextStyle(
                            color: _category == c
                                ? Colors.white
                                : AppTheme.inkFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _category = c),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            GradientButton(
              label: _isEditing ? 'Save changes' : 'Save transaction',
              icon: Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
