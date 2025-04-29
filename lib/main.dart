import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meu_caderninho/screens/esqueci_senha_screen.dart';
import 'package:meu_caderninho/screens/grupo_list_screen.dart';
import 'package:meu_caderninho/screens/meus_lancamentos_screen.dart';
import 'package:meu_caderninho/screens/perfil_screen.dart';
import 'package:meu_caderninho/screens/wrapper_screen.dart';

import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDRogm2HAHU9NLBJOA9oX93NM6jl9Lgx4E",
        authDomain: "meu-caderninho.firebaseapp.com",
        projectId: "meu-caderninho",
        storageBucket: "meu-caderninho.firebasestorage.app",
        messagingSenderId: "279522702993",
        appId: "1:279522702993:web:b766073f1a39388f14f130",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MeuCaderninhoApp());
}

class MeuCaderninhoApp extends StatelessWidget {
  const MeuCaderninhoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Caderninho',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // 🆕 ATIVA Material 3!
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B1B54), // Azul escuro que você já usa
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B54),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B1B54),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),

      routes: {
        '/': (context) => const WrapperScreen(), // ✅ agora ele decide
        '/cadastro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(),
        '/esqueci-senha': (context) => const EsqueciSenhaScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/lista-grupo': (context) => const GrupoListScreen(),
        '/meus-lancamentos': (context) => const MeusLancamentosScreen(),
      },
    );
  }
}
