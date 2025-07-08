import 'dart:io';
import 'dart:typed_data'; // <- IMPORT ADICIONADO
import 'package:flutter/foundation.dart' show kIsWeb; // Importa o kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;

  // Armazena os dados da imagem de forma compatível com web e mobile
  XFile? _imageFile;
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Lê os bytes da imagem (se for web) ANTES de atualizar o estado.
      // Isso garante que todos os dados da imagem estejam prontos antes da UI tentar reconstruir.
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
      }

      // Atualiza o estado com ambos os dados da imagem (arquivo e bytes) de uma só vez.
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva algo ou adicione uma imagem para postar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      final userId = supabase.auth.currentUser!.id;

      // 1. Fazer upload da imagem, se houver
      if (_imageFile != null) {
        // A lógica de upload já era compatível, pois lê os bytes do arquivo.
        final imageBytes = await _imageFile!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '$userId/$fileName';

        await supabase.storage.from('post_images').uploadBinary(filePath, imageBytes);
        imageUrl = supabase.storage.from('post_images').getPublicUrl(filePath);
      }

      // 2. Inserir o post no banco de dados
      await supabase.from('posts').insert({
        'user_id': userId,
        'content': _contentController.text,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post criado com sucesso!')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Post'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: const Text('Postar', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'O que você está pensando?',
                border: InputBorder.none,
              ),
              maxLength: 100,
              maxLines: null,
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  // Lógica para exibir a imagem
                  kIsWeb
                      ? Image.memory( // Usa Image.memory para a web
                    _imageBytes!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Image.file( // Mantém Image.file para mobile
                    File(_imageFile!.path),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                        _imageBytes = null;
                      });
                    },
                  )
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Adicionar Foto'),
              ),
          ],
        ),
      ),
    );
  }
}
