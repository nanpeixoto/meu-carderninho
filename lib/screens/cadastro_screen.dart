import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';


class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  DateTime? _dataNascimento;
  String? _genero;
  bool _aceitouTermos = false;
  File? _avatar;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        _nomeController.text = args['nome'] ?? '';
        _emailController.text = args['email'] ?? '';
        _avatarUrl = args['foto'];
        setState(() {});
      }
    });
  }

  Future<void> _selecionarAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
        _avatarUrl = null;
      });
    }
  }

  Widget _buildAvatar() {
    if (_avatar != null) {
      return CircleAvatar(radius: 40, backgroundImage: FileImage(_avatar!));
    } else if (_avatarUrl != null) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(_avatarUrl!),
      );
    } else {
      return const CircleAvatar(radius: 40, child: Icon(Icons.camera_alt));
    }
  }

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      if (!_aceitouTermos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você precisa aceitar os termos")),
        );
        return;
      }

      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _senhaController.text,
            );

        await credential.user?.updateDisplayName(_nomeController.text.trim());
        await credential.user
            ?.reload(); // força o Firebase a atualizar o perfil em memóri

        final userId = credential.user?.uid;

        await FirebaseFirestore.instance.collection('usuarios').doc(userId).set(
          {
            'nome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
            'celular': _celularController.text.trim(),
            'genero': _genero,
            'dataNascimento': _dataNascimento?.toIso8601String(),
            'avatarUrl': _avatarUrl,
            'criadoEm': FieldValue.serverTimestamp(),
            'pesquisa': [
              ..._nomeController.text.trim().toLowerCase().split(' '),
              _emailController.text.trim().toLowerCase(),
            ],
          },
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao registrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(onTap: _selecionarAvatar, child: _buildAvatar()),
              const SizedBox(height: 16),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe um e-mail';
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                  if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
                  return null;
                },
              ),

              // Celular
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                validator:
                    (v) =>
                        v != null && v.length >= 14
                            ? null
                            : 'Informe um número válido',
              ),

              // Data de nascimento
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Data de nascimento: "),
                  TextButton(
                    onPressed: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
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
                    ),
                  ),
                ],
              ),

              // Gênero
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gênero'),
                value: _genero,
                items: const [
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                ],
                onChanged: (value) => setState(() => _genero = value),
                validator: (v) => v == null ? 'Selecione o gênero' : null,
              ),

              // Senhas
              const SizedBox(height: 12),
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator:
                    (v) =>
                        v != null && v.length >= 6
                            ? null
                            : 'Mínimo 6 caracteres',
              ),
              TextFormField(
                controller: _confirmarSenhaController,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                obscureText: true,
                validator:
                    (v) =>
                        v != _senhaController.text
                            ? 'Senhas não conferem'
                            : null,
              ),

              // Aceite
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _aceitouTermos,
                onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
                title: const Text("Aceito os termos de uso"),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registrar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text("Registrar", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
