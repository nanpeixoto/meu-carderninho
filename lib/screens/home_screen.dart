import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Caderninho')),
      drawer: const CustomDrawer(),
      body: const Center(
        child: Text('Bem-vindo à tela inicial!'),
      ),
    );
  }
}
