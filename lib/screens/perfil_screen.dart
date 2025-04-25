import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();
  DateTime? _dataNascimento;
  String? _genero;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .get();

    final dados = doc.data() ?? {};
    _nomeController.text = dados['nome'] ?? '';
    _celularController.text = dados['celular'] ?? '';
    _genero = dados['genero'];
    if (dados['dataNascimento'] != null) {
      _dataNascimento = DateTime.tryParse(dados['dataNascimento']);
    }

    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({
            'nome': _nomeController.text.trim(),
            'celular': _celularController.text.trim(),
            'genero': _genero,
            'dataNascimento': _dataNascimento?.toIso8601String(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados atualizados com sucesso.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nome completo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _nomeController,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Campo obrigatório'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Celular',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _celularController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        validator:
                            (v) =>
                                v != null && v.length >= 14
                                    ? null
                                    : 'Número inválido',
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Data de nascimento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: _dataNascimento ?? DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (data != null) {
                            setState(() => _dataNascimento = data);
                          }
                        },
                        child: Text(
                          _dataNascimento != null
                              ? "${_dataNascimento!.day}/${_dataNascimento!.month}/${_dataNascimento!.year}"
                              : "Selecionar",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Gênero',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _genero,
                        items: const [
                          DropdownMenuItem(
                            value: 'Feminino',
                            child: Text('Feminino'),
                          ),
                          DropdownMenuItem(
                            value: 'Masculino',
                            child: Text('Masculino'),
                          ),
                          DropdownMenuItem(
                            value: 'Outro',
                            child: Text('Outro'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _genero = value),
                        validator:
                            (v) => v == null ? 'Selecione o gênero' : null,
                      ),

                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1B1B54,
                          ), // Azul escuro
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Salvar alterações",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
