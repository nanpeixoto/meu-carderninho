import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InformarPagamentoScreen extends StatelessWidget {
  final String destinatarioNome;
  final double valor;
  final String docId;

  const InformarPagamentoScreen({
    super.key,
    required this.destinatarioNome,
    required this.valor,
    required this.docId,
  });

  Future<void> _enviarParaAprovacao(BuildContext context) async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('gastos').get();

    for (var doc in snapshot.docs) {
      if (doc.id == docId) {
        await doc.reference.update({'status': 'Aguardando Aprovação'});
        break;
      }
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informar Pagamento'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para $destinatarioNome',
                style: const TextStyle(fontSize: 16)),
            Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Observações',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Digite algum detalhe ou comentário',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Comprovante',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // TODO: abrir galeria/câmera
              },
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(height: 4),
                    Text('Carregar comprovante',
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _enviarParaAprovacao(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ENVIAR PARA APROVAÇÃO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
