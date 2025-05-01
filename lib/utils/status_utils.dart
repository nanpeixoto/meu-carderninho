import 'package:flutter/material.dart';

Color backgroundStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'aprovado':
      return Colors.green.shade50;
    case 'rejeitado':
      return Colors.red.shade50;
    case 'pago':
      return Colors.blue.shade50;
    case 'aguardando aprovação':
    case 'aguardando aprovação pagamento':
      return Colors.orange.shade50;
    case 'pendente':
    default:
      return Colors.grey.shade200;
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
    case 'aguardando aprovação':
    case 'aguardando aprovação pagamento':
      return Colors.orange;
    case 'pendente':
    default:
      return Colors.grey;
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
    case 'aguardando aprovação':
    case 'aguardando aprovação pagamento':
      return Icons.hourglass_top;
    case 'pendente':
    default:
      return Icons.help_outline;
  }
}

String formatarStatus(String status) {
  switch (status.toLowerCase()) {
    case 'aprovado':
      return 'Aprovado';
    case 'rejeitado':
      return 'Rejeitado';
    case 'pago':
      return 'Pago';
    case 'aguardando aprovação':
      return 'Aguardando Aprovação';
    case 'aguardando aprovação pagamento':
      return 'Aguardando Pagamento';
    case 'pendente':
    default:
      return 'Pendente';
  }
}
