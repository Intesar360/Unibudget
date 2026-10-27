/// Small formatting helpers, kept dependency-free (no `intl` needed).
/// All money is shown in Bangladeshi Taka, matching the mockups.

String formatMoney(double amount) {
  final sign = amount < 0 ? '-' : '';
  return '$sign৳${amount.abs().toStringAsFixed(2)}';
}

String formatSignedMoney(double amount, {required bool isIncome}) {
  final prefix = isIncome ? '+' : '-';
  return '$prefix${formatMoney(amount)}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 1 Oct 2026
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// October 2026 — used as a History section header.
String formatMonthYear(DateTime date) =>
    '${_monthName(date.month)} ${date.year}';

String _monthName(int month) => const [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ][month - 1];
