import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeusLancamentosScreen extends StatefulWidget {
  const MeusLancamentosScreen({super.key});

  @override  
  State<MeusLancamentosScreen> createState() => _MeusLancamentosScreenState();  
}

class _MeusLancamentosScreenState extends State<MeusLancamentosScreen> {
  List<QueryDocumentSnapshot> _docs = [];
  bool _carregando = true;
  
  String _filtroStatus = 'Todos'; // <- Adicione isso no topo do State

  @override
  void initState() {    
    super.initState();
    _carregarLancamentos();
  }

  Future<void> _carregarLancamentos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collectionGroup('gastos')
            .where('divididoEntre', arrayContains: userId)
            .get();

    setState(() {
      _docs = querySnapshot.docs;
      _carregando = false;
    });
  }

  Future<void> _atualizarStatus(String docId, String novoStatus) async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('gastos').get();

    for (var doc in snapshot.docs) {
      if (doc.id == docId) {
        await doc.reference.update({'status': novoStatus});
        break;
      }
    }

    // Atualizar a lista localmente
    setState(() {
      // Atualiza o status do documento na lista local
      // Isso é necessário para que o widget seja reconstruído com o novo status
      final index = _docs.indexWhere((doc) => doc.id == docId);
      if (index != -1) {
        final data = _docs[index].data() as Map<String, dynamic>;
        data['status'] = novoStatus;
        _docs[index] = _docs[index]; // força rebuild
      }
    });
  }

  String _getNomeMes(int mes) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return meses[mes - 1];
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
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Text("Filtrar: "),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filtroStatus,
                          items: const [
                            DropdownMenuItem(
                              value: 'Todos',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem(
                              value: 'Pendente',
                              child: Text('Pendente'),
                            ),
                            DropdownMenuItem(
                              value: 'Aprovado',
                              child: Text('Aprovado'),
                            ),
                            DropdownMenuItem(
                              value: 'Rejeitado',
                              child: Text('Rejeitado'),
                            ),
                            DropdownMenuItem(
                              value: 'Pago',
                              child: Text('Pago'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _docs.isEmpty
                            ? const Center(
                              child: Text('Nenhum lançamento encontrado.'),
                            )
                            : ListView.builder(
                              itemCount: _docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    _docs[index].data() as Map<String, dynamic>;
                                final status = data['status'] ?? 'Pendente';

                                if (_filtroStatus != 'Todos' &&
                                    status != _filtroStatus) {
                                  return const SizedBox.shrink(); // Oculta item que não bate com filtro
                                }

                                final docId = _docs[index].id;
                                final nome =
                                    data['lancadoPorNome'] ?? 'Usuário';
                                final valor = data['valor'] ?? 0.0;
                                final categoria = data['categoria'] ?? '';
                                final dataLancamento =
                                    (data['data'] as Timestamp?)?.toDate();
                                final List<dynamic> participantes =
                                    data['divididoEntre'] ?? [];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              radius: 24,
                                              child: Text(
                                                nome.isNotEmpty
                                                    ? nome[0].toUpperCase()
                                                    : 'U',
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    participantes.length > 1
                                                        ? '$nome lançou um gasto de R\$${valor.toStringAsFixed(2)} para dividir com você'
                                                        : '$nome lançou um gasto de R\$${valor.toStringAsFixed(2)} para você',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    categoria,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    dataLancamento != null
                                                        ? participantes.length >
                                                                1
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
                                                  onPressed:
                                                      () => _atualizarStatus(
                                                        docId,
                                                        'Rejeitado',
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        Colors.black87,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      side: BorderSide(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade300,
                                                      ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                    color: Colors.black54,
                                                  ),
                                                  label: const Text(
                                                    'REJEITAR',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed:
                                                      () => _atualizarStatus(
                                                        docId,
                                                        'Aprovado',
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'APROVAR',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    status == 'Aprovado'
                                                        ? Colors.green.shade50
                                                        : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    status == 'Aprovado'
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    color:
                                                        status == 'Aprovado'
                                                            ? Colors.green
                                                            : Colors.red,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      color:
                                                          status == 'Aprovado'
                                                              ? Colors.green
                                                              : Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                            ),
                  ),
                ],
              ),
    );
  }
}
