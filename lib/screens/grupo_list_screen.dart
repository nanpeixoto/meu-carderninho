import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'novo_grupo_screen.dart';
import 'editar_grupo_screen.dart';
import '../widgets/custom_drawer.dart';

class GrupoListScreen extends StatefulWidget {
  const GrupoListScreen({super.key});

  @override
  State<GrupoListScreen> createState() => _GrupoListScreenState();
}

class _GrupoListScreenState extends State<GrupoListScreen> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtro = '';
  final String? _uidUsuario = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Grupos')),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar grupo por nome',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filtro = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grupos')
                  .orderBy('nome')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum grupo encontrado'));
                }

                final gruposFiltrados = snapshot.data!.docs.where((grupo) {
                  final dados = grupo.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? '').toString().toLowerCase();
                  final criadoPor = dados['criadoPor'];
                  return nome.contains(_filtro) && criadoPor == _uidUsuario;
                }).toList();

                if (gruposFiltrados.isEmpty) {
                  return const Center(child: Text('Nenhum grupo corresponde à busca.'));
                }

                return ListView.separated(
                  itemCount: gruposFiltrados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final grupo = gruposFiltrados[index];
                    final dados = grupo.data() as Map<String, dynamic>;
                    final nome = (dados['nome'] ?? 'Grupo').toString();
                    final participantes = dados['participantes'] ?? [];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1B1B54),
                        child: Text(
                          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${participantes.length} participantes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditarGrupoScreen(
                              grupoId: grupo.id,
                              nomeAtual: nome,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoGrupoScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Grupo'),
        backgroundColor: const Color(0xFF1B1B54),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
