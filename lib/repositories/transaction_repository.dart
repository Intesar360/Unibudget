import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/transaction.dart';

/// The single place screens talk to for data. Screens never care whether
/// the data is local or from Django — that is the whole point for
/// Phase 3: swap [MockTransactionRepository] for
/// [ApiTransactionRepository] in main.dart and nothing else changes.
abstract class TransactionRepository {
  Future<List<Transaction>> fetchAll();
  Future<Transaction> add(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
}

/// Phase 2 implementation: in-memory demo data. Persists for the session.
class MockTransactionRepository implements TransactionRepository {
  final List<Transaction> _items = List.of(demoTransactions);

  @override
  Future<List<Transaction>> fetchAll() async => List.of(_items);

  @override
  Future<Transaction> add(Transaction transaction) async {
    _items.add(transaction);
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final index = _items.indexWhere((t) => t.id == transaction.id);
    if (index != -1) _items[index] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((t) => t.id == id);
  }
}

/// Store: holds the list and derives EVERY number screens show.
/// No screen is allowed to hard-code a total — that rule is what keeps
/// Home, History and Budgets agreeing with each other.
class TransactionStore extends ChangeNotifier {
  final TransactionRepository _repository;
  List<Transaction> _transactions = [];

  TransactionStore(this._repository);

  Future<void> load() async {
    _transactions = await _repository.fetchAll();
    _sort();
    notifyListeners();
  }

  List<Transaction> get all => List.unmodifiable(_transactions);

  /// Newest first.
  List<Transaction> get recent => _transactions.take(5).toList();

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  /// Expense only, by category — drives the Home breakdown bar.
  Map<Category, double> get spendingByCategory {
    final map = <Category, double>{};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  /// Grouped newest-month first, for History. Key is DateTime(year, month).
  Map<DateTime, List<Transaction>> get groupedByMonth {
    final map = <DateTime, List<Transaction>>{};
    for (final t in _transactions) {
      final key = DateTime(t.date.year, t.date.month);
      map.putIfAbsent(key, () => []).add(t);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  double monthNet(List<Transaction> monthTransactions) =>
      monthTransactions.fold(
        0,
        (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
      );

  Future<void> add(Transaction transaction) async {
    final saved = await _repository.add(transaction);
    _transactions.add(saved);
    _sort();
    notifyListeners();
  }

  Future<void> update(Transaction transaction) async {
    await _repository.update(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) _transactions[index] = transaction;
    _sort();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Blank-account reset: called on login and on logout,
  /// so a new login never sees the previous session's data.
  void resetToEmpty() {
    _transactions = [];
    notifyListeners();
  }

  void _sort() =>
      _transactions.sort((a, b) => b.date.compareTo(a.date));
}
