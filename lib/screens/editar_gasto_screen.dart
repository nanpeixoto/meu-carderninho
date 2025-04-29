import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarGastoScreen extends StatefulWidget {
  final QueryDocumentSnapshot gasto;

  const EditarGastoScreen({super.key, required this.gasto});

  @override
  State<EditarGastoScreen> createState() => _EditarGastoScreenState();
}

class _EditarGastoScreenState extends State<EditarGastoScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _valorController;
  DateTime? _dataSelecionada;

  @override
  void initState() {
    super.initState();
    final dados = widget.gasto.data() as Map<String, dynamic>;
    _nomeController = TextEditingController(text: dados['nome']);
    _valorController = TextEditingController(text: dados['valor'].toString());
    _dataSelecionada = (dados['data'] as Timestamp?)?.toDate();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    final novoNome = _nomeController.text.trim();
    final novoValor = double.tryParse(_valorController.text.trim()) ?? 0.0;

    if (novoNome.isEmpty || novoValor <= 0 || _dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
      return;
    }

    await widget.gasto.reference.update({
      'nome': novoNome,
      'valor': novoValor,
      'data': Timestamp.fromDate(_dataSelecionada!),
    });

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Gasto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataSelecionada ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dataSelecionada = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data do gasto',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dataSelecionada != null
                        ? '${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'
                        : 'Selecionar data'),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarAlteracoes,
                child: const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
