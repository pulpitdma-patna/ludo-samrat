import 'package:flutter/material.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'won':
      return const Color(0xFF22C55E);
    case 'lost':
      return const Color(0xFFEF4444);
    case 'add':
      return const Color(0xFF3B82F6);
    case 'reward':
      return const Color(0xFFA855F7);
    case 'tournament':
      return const Color(0xFF22C55E);
    case 'withdraw':
      return const Color(0xFFEAB308);
    default:
      return Colors.grey;
  }
}

Color getTransactionColor(String status) {
  if (status.toLowerCase() == 'lost' || status.toLowerCase() == 'withdraw') {
    return const Color(0xFFEF4444);
  } else {
    return const Color(0xFF4ADE80);
  }
}

double parseAmount(dynamic amount) {
  if (amount == null) return 0.0;
  if (amount is num) return amount.toDouble();
  return double.tryParse(amount.toString()) ?? 0.0;
}

String formatAmount(dynamic amount) {
  final value = parseAmount(amount);
  return '₹${value.toStringAsFixed(2)}';
}
