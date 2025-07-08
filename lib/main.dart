import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/pt_br_messages.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- IMPORT ADICIONADO
import 'app.dart'; // Importa o widget principal do app

Future<void> main() async {
  // Garante que os bindings do Flutter foram inicializados
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  timeago.setLocaleMessages('pt_BR', PtBrMessages());

  // Inicializa o Supabase com suas credenciais
  await Supabase.initialize(
    url: 'https://vjlyxferkoefadlhqshy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqbHl4ZmVya29lZmFkbGhxc2h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4MjgwNzIsImV4cCI6MjA2NzQwNDA3Mn0.HpE-P4hlLTcXV3hhtWKLYGC5asEF2NZWmT3P_40V-PY',
  );

  // Inicia o aplicativo
  runApp(const Desafio90DiasApp());
}
