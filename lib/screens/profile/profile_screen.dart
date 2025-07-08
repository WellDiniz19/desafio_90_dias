import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- IMPORT ADICIONADO

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _weightHistory = [];
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final weightResponse = await supabase
          .from('weight_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _profileData = profileResponse;
        _avatarUrl = profileResponse['avatar_url'];
        _weightHistory = weightResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: imageFile.mimeType),
      );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      await supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

      setState(() {
        _avatarUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar atualizado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar avatar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPasswordChangeDialog() async {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar Senha'),
          content: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova Senha'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres.')),
                  );
                  return;
                }
                try {
                  await supabase.auth.updateUser(
                    UserAttributes(password: passwordController.text),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha alterada com sucesso!')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao alterar senha: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
          ? const Center(child: Text('Não foi possível carregar o perfil.'))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _uploadAvatar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Nome de Usuário'),
              subtitle: Text(_profileData!['username'] ?? 'Não informado'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.scale),
              title: const Text('Peso Inicial'),
              subtitle: Text('${_profileData!['initial_weight']} kg'),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _showPasswordChangeDialog,
              child: const Text('Alterar Senha'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          Text(
            'Histórico de Peso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _weightHistory.isEmpty
              ? const Center(child: Text('Nenhum peso registrado.'))
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _weightHistory.length,
            itemBuilder: (context, index) {
              final record = _weightHistory[index];
              final date = DateTime.parse(record['created_at']);
              final formattedDate = DateFormat('dd/MM/yyyy \'às\' HH:mm').format(date);
              return Card(
                child: ListTile(
                  title: Text('${record['weight']} kg'),
                  subtitle: Text(formattedDate),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
