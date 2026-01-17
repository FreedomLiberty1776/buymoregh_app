import 'package:uuid/uuid.dart';

/// Generate a unique client reference for idempotent requests
String generateClientReference() {
  final uuid = const Uuid().v4();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'APP-$timestamp-$uuid'.substring(0, 36);
}

/// Normalize Ghanaian phone number to 233XXXXXXXXX format
String normalizePhoneNumber(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (cleaned.startsWith('233')) {
    return cleaned;
  } else if (cleaned.startsWith('0')) {
    return '233${cleaned.substring(1)}';
  } else if (cleaned.length == 9) {
    return '233$cleaned';
  }
  
  return cleaned;
}

/// Detect mobile money provider from phone number
String getMobileMoneyProvider(String phone) {
  final normalized = normalizePhoneNumber(phone);
  
  if (normalized.length < 6) return 'unknown';
  
  final prefix = normalized.substring(3, 5);
  
  // MTN prefixes
  if (['24', '25', '53', '54', '55', '59'].contains(prefix)) {
    return 'mtn';
  }
  
  // Vodafone prefixes
  if (['20', '50'].contains(prefix)) {
    return 'vod';
  }
  
  // AirtelTigo prefixes
  if (['26', '27', '56', '57'].contains(prefix)) {
    return 'tgo';
  }
  
  return 'unknown';
}

/// Format currency for display
String formatCurrency(double amount, {String symbol = 'GHS', int decimals = 2}) {
  return '$symbol ${amount.toStringAsFixed(decimals)}';
}

/// Calculate payment percentage
double calculatePaymentPercentage(double totalPaid, double totalAmount) {
  if (totalAmount <= 0) return 0;
  return (totalPaid / totalAmount) * 100;
}

/// Check if a date is today
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// Check if a date is yesterday
bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return date.year == yesterday.year && 
         date.month == yesterday.month && 
         date.day == yesterday.day;
}

/// Get greeting based on time of day
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
