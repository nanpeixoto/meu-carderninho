import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditarGrupoScreen extends StatefulWidget {
  final String grupoId;
  final String nomeAtual;

  const EditarGrupoScreen({super.key, required this.grupoId, required this.nomeAtual});

  @override
  State<EditarGrupoScreen> createState() => _EditarGrupoScreenState();
}

class _EditarGrupoScreenState extends State<EditarGrupoScreen> {
  late TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeAtual);
  }

  Future<void> _salvarAlteracoes() async {
    final novoNome = _nomeController.text.trim();

    if (novoNome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome válido')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('grupos').doc(widget.grupoId).update({
      'nome': novoNome,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome do grupo atualizado')),
    );

    Navigator.pop(context); // Voltar para a tela anterior (GrupoDetalhesScreen)
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
        title: const Text('Editar Grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nome do grupo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite o novo nome',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarAlteracoes,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
