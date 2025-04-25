import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meu_caderninho/screens/grupo_detalhe_screen.dart';
 

class NovoGrupoScreen extends StatefulWidget {
  const NovoGrupoScreen({super.key});

  @override
  State<NovoGrupoScreen> createState() => _NovoGrupoScreenState();
}

class _NovoGrupoScreenState extends State<NovoGrupoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _carregando = false;

  Future<void> _criarGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final grupoRef = await FirebaseFirestore.instance.collection('grupos').add({
        'nome': _nomeController.text.trim(),
        'criadoPor': user?.uid,
        'participantes': [],
        'criadoEm': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo criado com sucesso!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GrupoDetalhesScreen(grupoId: grupoRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nome do grupo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeController,
                validator: (v) => v == null || v.isEmpty ? 'Informe um nome' : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Amigos da Faculdade',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _carregando ? null : _criarGrupo,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Criar Grupo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
