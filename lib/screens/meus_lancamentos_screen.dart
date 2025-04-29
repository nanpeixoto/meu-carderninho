import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeusLancamentosScreen extends StatelessWidget {
  const MeusLancamentosScreen({super.key});

  Future<void> _atualizarStatus(String id, String novoStatus) async {
    await FirebaseFirestore.instance.collection('lancamentos').doc(id).update({
      'status': novoStatus,
    });
  }

  Future<List<QueryDocumentSnapshot>> carregarLancamentos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('gastos')
        .where('divididoEntre', arrayContains: userId)        
        .get();

    return querySnapshot.docs;
  }

  Future<List<String>> _getNomesParticipantes(List<String> ids) async {
    final List<String> nomes = [];
    for (final id in ids) {
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
      nomes.add(userDoc.data()?['nome'] ?? 'Usuário');
    }
    return nomes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Meus Lançamentos', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E), // Cor escura como na imagem
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: carregarLancamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum lançamento encontrado.'));
          }

          final docs = snapshot.data!;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              final nome = data['lancadoPorNome'] ?? 'Usuário';
              final valor = data['valor'] ?? 0.0;
              final categoria = data['categoria'] ?? '';
              final status = data['status'] ?? 'Pendente';
              final dataLancamento = (data['data'] as Timestamp?)?.toDate();
              
              // Verificar a quantidade de participantes
              final List<dynamic> participantes = data['divididoEntre'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: data['lancadoPor'] == 'Usuário' 
                                ? Colors.blue.shade100 
                                : (data['lancadoPor'] == 'Fernanda' ? Colors.purple.shade100 : Colors.blue.shade100),
                            radius: 24,
                            child: Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: data['lancadoPor'] == 'Usuário' 
                                    ? Colors.blue.shade700
                                    : (data['lancadoPor'] == 'Fernanda' ? Colors.purple.shade700 : Colors.blue.shade700),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participantes.length > 1 
                                    ? '$nome lançou um gasto de R\$${valor.toStringAsFixed(2)} para dividir com você'
                                    : '$nome lançou um gasto de R\$${valor.toStringAsFixed(2)} para você',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  categoria,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dataLancamento != null
                                      ? participantes.length > 1 
                                          ? '${dataLancamento.day} de ${_getNomeMes(dataLancamento.month)} • Dividido por você, $nome'
                                          : '${dataLancamento.day} de ${_getNomeMes(dataLancamento.month)}'
                                      : '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (status == 'Pendente')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _atualizarStatus(docId, 'Rejeitado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(
                                  Icons.close, 
                                  size: 18, 
                                  color: Colors.black54,
                                ),
                                label: const Text(
                                  'REJEITAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _atualizarStatus(docId, 'Aprovado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(
                                  Icons.check, 
                                  size: 18,
                                ),
                                label: const Text(
                                  'APROVAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'Aprovado' 
                                  ? Colors.green.shade50 
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status == 'Aprovado' ? Icons.check_circle : Icons.cancel,
                                  color: status == 'Aprovado' ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'Aprovado' ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  String _getNomeMes(int mes) {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril',
      'maio', 'junho', 'julho', 'agosto',
      'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return meses[mes - 1];
  }
}