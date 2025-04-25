// lib/screens/editar_grupo_screen.dart
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeAtual);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    await FirebaseFirestore.instance
        .collection('grupos')
        .doc(widget.grupoId)
        .update({'nome': _nomeController.text.trim()});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grupo atualizado com sucesso')),
    );
    Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('grupos')
          .doc(widget.grupoId)
          .delete();

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Grupo')),
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
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1B54),
                ),
                child: _salvando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar alterações'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _excluir,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir grupo'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
