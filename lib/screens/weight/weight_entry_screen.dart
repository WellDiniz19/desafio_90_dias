import 'package:flutter/material.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';

class WeightEntryScreen extends StatefulWidget {
  const WeightEntryScreen({super.key});

  @override
  State<WeightEntryScreen> createState() => _WeightEntryScreenState();
}

class _WeightEntryScreenState extends State<WeightEntryScreen> {
  final _weightController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um peso válido.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.from('weight_entries').insert({
        'user_id': supabase.auth.currentUser!.id,
        'weight': weight,
      });
      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso registrado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar peso: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrar Nova Pesagem', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Peso Atual (kg)',
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addWeight,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Pesagem'),
              ),
            ),
        ],
      ),
    );
  }
}