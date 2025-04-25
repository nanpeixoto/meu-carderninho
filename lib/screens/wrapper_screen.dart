import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meu_caderninho/screens/login_screen.dart';
import 'grupo_list_screen.dart';
import 'login_screen.dart';

class WrapperScreen extends StatelessWidget {
  const WrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Verifica se usuário está logado
    if (user != null) {
      return const GrupoListScreen();
    } else {
      return const LoginScreen();
    }
  }
}
