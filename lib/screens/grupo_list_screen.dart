import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meu_caderninho/screens/grupo_detalhe_screen.dart';
import 'package:meu_caderninho/widgets/custom_drawer.dart';
import 'novo_grupo_screen.dart';

class GrupoListScreen extends StatefulWidget {
  const GrupoListScreen({super.key});

  @override
  State<GrupoListScreen> createState() => _GrupoListScreenState();
}

class _GrupoListScreenState extends State<GrupoListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Widget _buildConvites() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
      .collection('convites')
      .where('enviadoPor', isEqualTo: userId) // Aqui filtramos pelo usuário que enviou
      .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final convites = snapshot.data!.docs;
      if (convites.isEmpty) {
        return const Center(child: Text('Nenhum convite enviado.'));
      }

      return ListView.builder(
        itemCount: convites.length,
        itemBuilder: (context, index) {
          final convite = convites[index];
          final email = convite['email'] ?? '';
          final status = convite['status'] ?? 'pendente';
          final grupoId = convite['grupoId'] ?? '';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('grupos').doc(grupoId).get(),
            builder: (context, grupoSnapshot) {
              final grupoNome = grupoSnapshot.data?.exists == true
                  ? grupoSnapshot.data!['nome'] ?? 'Grupo desconhecido'
                  : 'Grupo desconhecido';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: $status\nGrupo: $grupoNome'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Criados por Mim'),
            Tab(text: 'Participando'),
            Tab(text: 'Convites'), // 🆕 Nova aba
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrupos(userFilter: 'criadoPor', compareValue: userId!, excludeUser: false),
          _buildGrupos(userFilter: 'participantes', compareValue: userId!, excludeUser: true),
          _buildConvites(), // 🆕 Nova tela
        ],
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoGrupoScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrupos({
    required String userFilter,
    required String compareValue,
    required bool excludeUser,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grupos')
          .where(userFilter, isEqualTo: compareValue)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allGroups = snapshot.data!.docs;
        final grupos = excludeUser
            ? allGroups.where((doc) => doc['criadoPor'] != userId).toList()
            : allGroups;

        if (grupos.isEmpty) {
          return const Center(child: Text('Nenhum grupo encontrado.'));
        }

        return ListView.builder(
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupos[index];
            final nome = grupo['nome'] ?? 'Grupo sem nome';
            final membros = List<String>.from(grupo['participantes'] ?? []);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
                ),
                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${membros.length} ${membros.length == 1 ? "membro" : "membros"}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrupoDetalhesScreen(grupoId: grupo.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}