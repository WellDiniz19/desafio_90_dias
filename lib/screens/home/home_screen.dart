import 'package:flutter/material.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';
import 'package:desafio_90_dias/screens/feed/create_post_screen.dart';
import 'package:desafio_90_dias/screens/feed/feed_screen.dart';
import 'package:desafio_90_dias/screens/leaderboard/leaderboard_screen.dart';
import 'package:desafio_90_dias/screens/profile/profile_screen.dart'; // Importa a nova tela
import 'package:desafio_90_dias/screens/weight/weight_entry_screen.dart';
import 'package:desafio_90_dias/screens/activity/activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Adiciona a ProfileScreen à lista de telas da navegação
  static const List<Widget> _widgetOptions = <Widget>[
    FeedScreen(),
    LeaderboardScreen(),
    WeightEntryScreen(),
    ActivityScreen(),
    ProfileScreen(), // <- TELA DE PERFIL ADICIONADA
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desafio 90 Dias'),
        actions: [
          // O botão de perfil foi removido daqui
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Pesar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Treinos',
          ),
          // Adiciona o novo item para a tela de Perfil
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}