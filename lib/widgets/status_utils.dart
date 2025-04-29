import 'package:flutter/material.dart';

Color backgroundStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'aprovado':
      return Colors.green.shade50;
    case 'rejeitado':
      return Colors.red.shade50;
    case 'pago':
      return Colors.blue.shade50;
    case 'pendente':
    default:
      return Colors.orange.shade50;
  }
}

Color textStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'aprovado':
      return Colors.green;
    case 'rejeitado':
      return Colors.red;
    case 'pago':
      return Colors.blue;
    case 'pendente':
    default:
      return Colors.orange;
  }
}

IconData iconeStatus(String status) {
  switch (status.toLowerCase()) {
    case 'aprovado':
      return Icons.check_circle;
    case 'rejeitado':
      return Icons.cancel;
    case 'pago':
      return Icons.attach_money;
    case 'pendente':
    default:
      return Icons.hourglass_top;
  }
}

String formatarStatus(String status) {
  if (status.isEmpty) return '';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}
