import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'nova_categoria_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({Key? key}) : super(key: key);

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  bool _mostrarInativos = false;

  @override
  Widget build(BuildContext context) {
    final usuarioId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Categorias'),
        actions: [
          Row(
            children: [
              const Text('Mostrar inativos', style: TextStyle(fontSize: 12)),
              Switch(
                value: _mostrarInativos,
                onChanged: (value) {
                  setState(() {
                    _mostrarInativos = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categorias')
            .where('usuarioId', isEqualTo: usuarioId)
           // .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma categoria cadastrada ainda.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final categorias = snapshot.data!.docs.where((categoria) {
            final ativo = categoria['ativo'] ?? true;
            if (_mostrarInativos) return true;
            return ativo == true;
          }).toList();

          if (categorias.isEmpty) {
            return const Center(child: Text('Nenhuma categoria para mostrar.'));
          }

          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              final nome = categoria['nome'] ?? '';
              final rawIcon = categoria['icone'];
              final iconeCode = rawIcon is int
                  ? rawIcon
                  : int.tryParse(rawIcon.toString()) ?? Icons.category.codePoint;
              final ativo = categoria['ativo'] ?? true;

              return ListTile(
                leading: Icon(
                  IconData(iconeCode, fontFamily: 'MaterialIcons'),
                ),
                title: Text(nome),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: ativo,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('categorias')
                            .doc(categoria.id)
                            .update({'ativo': value});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NovaCategoriaScreen(
                              categoriaId: categoria.id,
                              nomeInicial: nome,
                              iconeInicial: iconeCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovaCategoriaScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
