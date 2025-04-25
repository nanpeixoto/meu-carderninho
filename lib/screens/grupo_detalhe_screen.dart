import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'editar_grupo_screen.dart';
import 'package:meu_caderninho/widgets/membro_card.dart';
import 'package:meu_caderninho/widgets/usuario_busca_card.dart';
import 'package:meu_caderninho/widgets/campo_convite_email.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GrupoDetalhesScreen extends StatefulWidget {
  final String grupoId;

  const GrupoDetalhesScreen({super.key, required this.grupoId});

  @override
  State<GrupoDetalhesScreen> createState() => _GrupoDetalhesScreenState();
}

class _GrupoDetalhesScreenState extends State<GrupoDetalhesScreen> {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _nomeGrupo = '';
  List<String> _participantes = [];
  double _totalMes = 820.00; // mock
  final Map<String, double> _saldos = {
    'João': 45.00,
    'Marina': 80.00,
    'Pedro': 125.00,
  };

  @override
  void initState() {
    super.initState();
    _carregarGrupo();
  }

  Future<void> _carregarGrupo() async {
    final doc = await FirebaseFirestore.instance.collection('grupos').doc(widget.grupoId).get();
    if (doc.exists) {
      setState(() {
        _nomeGrupo = doc['nome'] ?? '';
        _participantes = List<String>.from(doc['participantes'] ?? []);
      });
    }
  }

  Future<void> _adicionarUsuario(String usuarioId, String email) async {
    if (_participantes.contains(usuarioId)) return;

    await FirebaseFirestore.instance.collection('grupos').doc(widget.grupoId).update({
      'participantes': FieldValue.arrayUnion([usuarioId])
    });

    setState(() {
      _participantes.add(usuarioId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário adicionado com sucesso!')),
    );
  }

  Future<void> _enviarConvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    await FirebaseFirestore.instance.collection('convites').add({
      'grupoId': widget.grupoId,
      'email': email,
      'status': 'pendente',
      'enviadoEm': FieldValue.serverTimestamp(),
      'enviadoPor': FirebaseAuth.instance.currentUser?.uid,
    });

    _emailController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Convite enviado para $email')),
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grupo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarGrupoScreen(
                    grupoId: widget.grupoId,
                    nomeAtual: _nomeGrupo,
                  ),
                ),
              );
              await _carregarGrupo();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total no mês', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('R\$ ${_totalMes.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              initiallyExpanded: false,
              title: const Text('Saldos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              children: [
                Column(
                  children: _saldos.entries.map((entry) => ListTile(
                    leading: CircleAvatar(child: Text(entry.key[0])),
                    title: Text(entry.key),
                    trailing: Text('R\$ ${entry.value.toStringAsFixed(2)}'),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () {},
                    label: const Text('Adicionar Gasto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC727),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            
            const SizedBox(height: 24),
            ExpansionTile(
              initiallyExpanded: false,
              title: const Text('Membros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final usuarios = snapshot.data!.docs.where((doc) => _participantes.contains(doc.id)).toList();
                    if (usuarios.isEmpty) return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Nenhum membro.'),
                    );

                    return Column(
                      children: usuarios.map((usuario) {
                        final nome = usuario['nome'] ?? '';
                        final email = usuario['email'] ?? '';
                        return MembroCard(nome: nome, email: email);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Adicionar Membro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _buscaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou e-mail',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                if (_buscaController.text.length > 2)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .where('email', isGreaterThanOrEqualTo: _buscaController.text.trim().toLowerCase())
                        .where('email', isLessThanOrEqualTo: _buscaController.text.trim().toLowerCase() + '\uf8ff')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final usuarios = snapshot.data!.docs;
                      if (usuarios.isEmpty) return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Nenhum usuário encontrado.'),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: usuarios.map((usuario) {
                            final id = usuario.id;
                            final nome = usuario['nome'] ?? '';
                            final email = usuario['email'] ?? '';
                            final jaEstaNoGrupo = _participantes.contains(id);

                            return UsuarioBuscaCard(
                              nome: nome,
                              email: email,
                              jaEstaNoGrupo: jaEstaNoGrupo,
                              onAdicionar: () => _adicionarUsuario(id, email),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Convidar por E-mail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CampoConviteEmail(
                    controller: _emailController,
                    onEnviar: _enviarConvite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
