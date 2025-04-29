import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NovaCategoriaScreen extends StatefulWidget {
  final String? categoriaId;
  final String? nomeInicial;
  final int? iconeInicial;

  const NovaCategoriaScreen({Key? key, this.categoriaId, this.nomeInicial, this.iconeInicial}) : super(key: key);

  @override
  State<NovaCategoriaScreen> createState() => _NovaCategoriaScreenState();
}

class _NovaCategoriaScreenState extends State<NovaCategoriaScreen> {
  final TextEditingController _nomeController = TextEditingController();
  int _iconeSelecionado = Icons.category.codePoint;
  bool _salvando = false;

  final List<IconData> _iconesDisponiveis = [
    Icons.shopping_cart,
    Icons.fastfood,
    Icons.home,
    Icons.car_rental,
    Icons.local_cafe,
    Icons.movie,
    Icons.flight,
    Icons.healing,
    Icons.school,
    Icons.pets,
    Icons.sports_soccer,
    Icons.work,
    Icons.attach_money,
    Icons.fitness_center,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.nomeInicial != null) {
      _nomeController.text = widget.nomeInicial!;
    }
    if (widget.iconeInicial != null) {
      _iconeSelecionado = widget.iconeInicial!;
    }
  }

  Future<void> _salvarCategoria() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da categoria.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final usuarioId = FirebaseAuth.instance.currentUser!.uid;
    final dadosCategoria = {
      'nome': nome,
      'icone': _iconeSelecionado,
      'usuarioId': usuarioId,
      'ativo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    };

    if (widget.categoriaId == null) {
      await FirebaseFirestore.instance.collection('categorias').add(dadosCategoria);
    } else {
      await FirebaseFirestore.instance.collection('categorias').doc(widget.categoriaId).update({
        'nome': nome,
        'icone': _iconeSelecionado,
      });
    }

    setState(() => _salvando = false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoriaId == null ? 'Nova Categoria' : 'Editar Categoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nome da categoria'),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite o nome',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Escolha um ícone'),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: _iconesDisponiveis.map((icone) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _iconeSelecionado = icone.codePoint;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _iconeSelecionado == icone.codePoint
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                      ),
                      child: Icon(
                        icone,
                        color: Colors.black87,
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvarCategoria,
                child: _salvando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.categoriaId == null ? 'Salvar Categoria' : 'Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
