import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GrupoScreen extends StatelessWidget {
  final String nomeGrupo;
  final String grupoId;

  const GrupoScreen({super.key, required this.nomeGrupo, required this.grupoId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(nomeGrupo),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Detalhes'),
              Tab(text: 'Adicionar Membro'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DetalhesTab(),
            AdicionarMembroTab(grupoId: grupoId),
          ],
        ),
      ),
    );
  }
}

class DetalhesTab extends StatelessWidget {
  const DetalhesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFFF7D1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Total no mês', style: TextStyle(color: Colors.black54)),
                  SizedBox(height: 8),
                  Text('R\$ 820,00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Saldos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(child: Text('J')),
            title: Text('João'),
            trailing: Text('R\$ 45,00'),
          ),
          ListTile(
            leading: CircleAvatar(child: Text('M')),
            title: Text('Marina'),
            trailing: Text('R\$ 80,00'),
          ),
          ListTile(
            leading: CircleAvatar(child: Text('P')),
            title: Text('Pedro'),
            trailing: Text('R\$ 125,00'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class AdicionarMembroTab extends StatefulWidget {
  final String grupoId;

  const AdicionarMembroTab({super.key, required this.grupoId});

  @override
  State<AdicionarMembroTab> createState() => _AdicionarMembroTabState();
}

class _AdicionarMembroTabState extends State<AdicionarMembroTab> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();

  Future<void> _enviarConvite(String email) async {
    await FirebaseFirestore.instance.collection('convites').add({
      'grupoId': widget.grupoId,
      'email': email,
      'status': 'pendente',
      'enviadoEm': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Convite enviado para $email')),
    );

    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _buscaController,
            decoration: InputDecoration(
              hintText: 'Nome ou e-mail',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.grey.shade100,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs.where((doc) {
                final nome = doc['nome']?.toString().toLowerCase() ?? '';
                final email = doc['email']?.toString().toLowerCase() ?? '';
                final busca = _buscaController.text.toLowerCase();
                return nome.contains(busca) || email.contains(busca);
              }).toList();

              if (users.isEmpty) return const Text('Nenhum usuário encontrado.');

              return Column(
                children: users.map((user) {
                  final nome = user['nome'] ?? '';
                  final email = user['email'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(child: Text(nome.isNotEmpty ? nome[0] : '?')),
                    title: Text(nome),
                    subtitle: Text(email),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Add'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('Convidar por E-mail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Digite o e-mail',
              prefixIcon: const Icon(Icons.email),
              fillColor: Colors.grey.shade100,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  _enviarConvite(_emailController.text.trim());
                }
              },
              child: const Text('Enviar Convite'),
            ),
          ),
        ],
      ),
    );
  }
}