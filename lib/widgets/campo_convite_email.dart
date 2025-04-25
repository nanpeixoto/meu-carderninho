import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CampoConviteEmail extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;

  const CampoConviteEmail({
    super.key,
    required this.controller,
    required this.onEnviar,
  });

  @override
  State<CampoConviteEmail> createState() => _CampoConviteEmailState();
}

class _CampoConviteEmailState extends State<CampoConviteEmail> {
  bool _usuarioExiste = false;
  bool _checandoEmail = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onEmailChanged);
    super.dispose();
  }

  void _onEmailChanged() {
    final email = widget.controller.text.trim().toLowerCase();
    if (_emailValido(email)) {
      _verificarEmail(email);
    } else {
      setState(() {
        _usuarioExiste = false;
      });
    }
  }

  Future<void> _verificarEmail(String email) async {
    setState(() {
      _checandoEmail = true;
    });

    final query =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .where('email', isEqualTo: email)
            .get();

    setState(() {
      _usuarioExiste = query.docs.isNotEmpty;
      _checandoEmail = false;
    });
  }

  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Digite o e-mail',
                  prefixIcon: const Icon(Icons.email),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    _emailValido(email) && !_usuarioExiste && !_checandoEmail
                        ? widget.onEnviar
                        : null,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                  child:
                      _checandoEmail
                          ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : _emailValido(email) && !_usuarioExiste
                          ? const Icon(
                            Icons.check_circle,
                            key: ValueKey('check'),
                            color: Colors.green,
                          )
                          : const Icon(Icons.send, key: ValueKey('send')),
                ),
                label: const Text('Enviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: const Color(0xFF1B1B54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (email.isNotEmpty && !_emailValido(email))
          const Text('E-mail inválido.', style: TextStyle(color: Colors.red)),

        if (_usuarioExiste && _emailValido(email))
          const Text(
            'Este e-mail já possui cadastro.',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }
}
