import 'package:flutter/material.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // O método foi ajustado para .asStream() para garantir a compilação.
  // Nota: .asStream() não escuta por atualizações em tempo real.
  // Para atualizações automáticas, o ideal é usar .stream(primaryKey: ['id'])
  // e garantir que o pacote supabase_flutter esteja atualizado.
  final _stream = supabase
      .from('posts')
      .select('*, profiles(username)') // Pede o username da tabela de perfis
      .order('created_at', ascending: false)
      .asStream(); // Converte a query em um Stream

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar o feed: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum post no feed ainda. Seja o primeiro!',
              textAlign: TextAlign.center,
            ),
          );
        }

        final posts = snapshot.data!;
        final currentUserId = supabase.auth.currentUser!.id;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            // Extrai os dados do perfil que vieram junto com o post.
            final profile = post['profiles'];
            // Se o perfil existir, pega o username; senão, usa um texto padrão.
            final username = profile != null ? profile['username'] : 'Usuário anônimo';

            final imageUrl = post['image_url'];
            final content = post['content'];
            final createdAt = DateTime.parse(post['created_at']);
            final isOwner = post['user_id'] == currentUserId;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    // AQUI O NOME DO USUÁRIO É EXIBIDO:
                    title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(timeago.format(createdAt, locale: 'pt_BR')),
                    trailing: isOwner
                        ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await supabase.from('posts').delete().eq('id', post['id']);
                        if(mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post removido!')),
                          );
                        }
                      },
                    )
                        : null,
                  ),
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 250,
                          child: Center(child: Icon(Icons.error)),
                        );
                      },
                    ),
                  if (content != null && content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(content),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
