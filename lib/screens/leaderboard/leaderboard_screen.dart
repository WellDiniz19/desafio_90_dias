import 'package:flutter/material.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('leaderboard').stream(primaryKey: ['user_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum participante ainda.'));
        }

        final leaderboard = snapshot.data!;

        return ListView.builder(
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final participant = leaderboard[index];
            final rank = index + 1;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank == 1 ? Colors.amber : Colors.teal,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(participant['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Peso: ${participant['weight_points']} pts | Atividade: ${participant['activity_points']} pts',
                ),
                trailing: Text(
                  '${participant['total_points']} pts',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}