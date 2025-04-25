import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user?.uid)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final nome = dados['nome'] ?? 'Usuário';
          final email = dados['email'] ?? user?.email ?? 'email@email.com';
          final foto = dados['avatarUrl'];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundImage: foto != null ? NetworkImage(foto) : null,
                  child:
                      foto == null ? const Icon(Icons.person, size: 40) : null,
                ),
                accountName: Text(nome),
                accountEmail: Text(email),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1B54), // 🌟 cor amarela do seu logo
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/perfil');
                },
              ),

              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Meus Grupos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/lista-grupo');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
