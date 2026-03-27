import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  // Date formatting
  static String formatDate(final DateTime date, {final String format = 'MMM dd, yyyy'}) => DateFormat(format).format(date);

  static String formatDateTime(final DateTime date, {final String format = 'MMM dd, yyyy HH:mm'}) => DateFormat(format).format(date);

  static String formatTime(final DateTime date, {final String format = 'HH:mm'}) => DateFormat(format).format(date);

  // Currency formatting
  static String formatCurrency(final double amount, {final String currency = '\$'}) => '$currency${amount.toStringAsFixed(2)}';

  // Number formatting
  static String formatNumber(final int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Validation helpers
  static bool isValidEmail(final String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  static bool isValidPassword(final String password) => password.length >= 6;

  static bool isValidPhone(final String phone) => RegExp(r'^\+?[\d\s-\(\)]+$').hasMatch(phone);

  // UI helpers
  static void showSnackBar(final BuildContext context, final String message, {final bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showCustomDialog(final BuildContext context, final Widget dialog) {
    showDialog(
      context: context,
      builder: (final context) => dialog,
    );
  }

  // String helpers
  static String capitalize(final String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncate(final String text, final int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Color helpers
  static Color darken(final Color color, [final double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(final Color color, [final double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
