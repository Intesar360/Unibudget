import 'package:flutter/material.dart';

enum TransactionType { income, expense }

/// Categories are split by type, exactly like the mockups:
/// income -> Salary / Allowance / Gift / Refund
/// expense -> Food / Transport / Bills / Study / Other
enum Category {
  food,
  transport,
  bills,
  study,
  salary,
  allowance,
  gift,
  refund,
  other,
}

extension CategoryUi on Category {
  String get label {
    switch (this) {
      case Category.food: return 'Food';
      case Category.transport: return 'Transport';
      case Category.bills: return 'Bills';
      case Category.study: return 'Study';
      case Category.salary: return 'Salary';
      case Category.allowance: return 'Allowance';
      case Category.gift: return 'Gift';
      case Category.refund: return 'Refund';
      case Category.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.food: return Icons.restaurant;
      case Category.transport: return Icons.directions_bus;
      case Category.bills: return Icons.home_outlined;
      case Category.study: return Icons.menu_book_outlined;
      case Category.salary: return Icons.account_balance_wallet_outlined;
      case Category.allowance: return Icons.card_giftcard_outlined;
      case Category.gift: return Icons.redeem_outlined;
      case Category.refund: return Icons.replay_outlined;
      case Category.other: return Icons.category_outlined;
    }
  }

  /// Soft background tint for the icon chip, kept from the mockups.
  Color get tint {
    switch (this) {
      case Category.food: return const Color(0xFFDCFCE7);
      case Category.transport: return const Color(0xFFDBEAFE);
      case Category.bills: return const Color(0xFFE0E7FF);
      case Category.study: return const Color(0xFFFEF3C7);
      case Category.salary: return const Color(0xFFD1FAE5);
      case Category.allowance: return const Color(0xFFDBEAFE);
      case Category.gift: return const Color(0xFFFCE7F3);
      case Category.refund: return const Color(0xFFE0E7FF);
      case Category.other: return const Color(0xFFF3F4F6);
    }
  }
}

const incomeCategories = [
  Category.salary,
  Category.allowance,
  Category.gift,
  Category.refund,
];

const expenseCategories = [
  Category.food,
  Category.transport,
  Category.bills,
  Category.study,
  Category.other,
];

/// One transaction. Field names match the Django REST API planned for
/// Phase 3 (see README.md), so `fromJson` / `toJson` need no rework then.
///
/// DRF note: DRF serialises money as a string ("5000.00") by default
/// with DecimalField. `fromJson` therefore accepts both String and num.
class Transaction {
  final String id;
  final String title;
  final double amount; // Always positive; [type] decides the sign.
  final TransactionType type;
  final Category category;
  final DateTime date;
  final String? paymentMethod; // e.g. 'Cash', 'bKash', 'Debit card •• 1842'

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.paymentMethod,
  });

  bool get isIncome => type == TransactionType.income;

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    Category? category,
    DateTime? date,
    String? paymentMethod,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is String
        ? double.parse(rawAmount)
        : (rawAmount as num).toDouble();
    return Transaction(
      id: json['id'].toString(),
      title: json['title'] as String,
      amount: amount,
      type: json['transaction_type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: Category.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => Category.other,
      ),
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['payment_method'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount.toStringAsFixed(2),
        'transaction_type': type.name,
        'category': category.name,
        'date': date.toIso8601String().split('T').first,
        'payment_method': paymentMethod,
      };
}
