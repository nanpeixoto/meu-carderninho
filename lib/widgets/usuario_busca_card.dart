import 'package:flutter/material.dart';
class UsuarioBuscaCard extends StatelessWidget {
  final String nome;
  final String email;
  final bool jaEstaNoGrupo;
  final VoidCallback onAdicionar;

  const UsuarioBuscaCard({
    super.key,
    required this.nome,
    required this.email,
    required this.jaEstaNoGrupo,
    required this.onAdicionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple.shade100,
            child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          jaEstaNoGrupo
              ? const Icon(Icons.check, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: onAdicionar,
                ),
        ],
      ),
    );
  }
}