import '../models/transaction.dart';

/// Blank account (v3 final fix).
///
/// The user asked for a clean, brand-new account on login:
/// no previous expenses, no previous transactions. So this
/// list is deliberately EMPTY. Balance, income and expense
/// all start at 0, and Home / History / Insights all show
/// empty states until the user adds a transaction with +.
///
/// This is also why the old demo totals (balance 900,
/// income 7500, expense 6600) no longer exist anywhere.
final demoTransactions = <Transaction>[];
