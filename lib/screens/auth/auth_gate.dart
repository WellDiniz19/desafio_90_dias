import 'package:flutter/material.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';
import 'package:desafio_90_dias/screens/home/home_screen.dart';
import 'package:desafio_90_dias/screens/auth/login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    } else {
      // CORREÇÃO: Usa um StreamBuilder para garantir que o perfil do usuário
      // exista antes de navegar para a tela principal.
      final profileStream = supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', session.user.id)
          .map((listOfMaps) => listOfMaps.isNotEmpty ? listOfMaps.first : null);

      return StreamBuilder<Map<String, dynamic>?>(
        stream: profileStream,
        builder: (context, snapshot) {
          // Enquanto o stream não tiver dados (ou seja, o perfil ainda não foi encontrado),
          // exibe uma tela de carregamento. Isso resolve a "corrida" contra o gatilho do banco.
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          // Assim que o perfil é encontrado, permite o acesso à HomeScreen.
          return const HomeScreen();
        },
      );
    }
  }
}
