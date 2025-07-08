// FILE: lib/screens/activity/activity_screen.dart
// DESC: Tela para o usuário registrar seus treinos em um calendário.

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:desafio_90_dias/api/supabase_client.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Estado para gerenciar o calendário
  late final ValueNotifier<List<DateTime>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Armazena os dias de treino buscados do banco
  HashSet<DateTime> _trainingDays = HashSet<DateTime>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchTrainingDays();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Busca os dias de treino do usuário no Supabase
  Future<void> _fetchTrainingDays() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('training_days')
          .select('training_date')
          .eq('user_id', userId);

      final HashSet<DateTime> fetchedDays = HashSet<DateTime>();
      for (var record in response) {
        // Converte a string de data para DateTime, ignorando a informação de fuso horário.
        final date = DateTime.parse(record['training_date']);
        fetchedDays.add(DateTime.utc(date.year, date.month, date.day));
      }

      setState(() {
        _trainingDays = fetchedDays;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar treinos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    // Retorna uma lista de eventos para um dia específico
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return _trainingDays.contains(utcDay) ? [utcDay] : [];
  }

  // Chamado quando o usuário toca em um dia no calendário
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
      _toggleTrainingDay(selectedDay);
    }
  }

  // Adiciona ou remove um dia de treino
  Future<void> _toggleTrainingDay(DateTime day) async {
    final userId = supabase.auth.currentUser!.id;
    final formattedDate = DateFormat('yyyy-MM-dd').format(day);
    final utcDay = DateTime.utc(day.year, day.month, day.day);

    final isTrainingDay = _trainingDays.contains(utcDay);

    try {
      if (isTrainingDay) {
        // Se já é um dia de treino, remove
        await supabase
            .from('training_days')
            .delete()
            .match({'user_id': userId, 'training_date': formattedDate});

        setState(() {
          _trainingDays.remove(utcDay);
        });
      } else {
        // Se não é, adiciona
        await supabase
            .from('training_days')
            .insert({'user_id': userId, 'training_date': formattedDate});

        setState(() {
          _trainingDays.add(utcDay);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar treino: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TableCalendar<DateTime>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            locale: 'pt_BR',
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              // Estilo para os marcadores de evento (dias de treino)
              markerDecoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              // Estilo para o dia de hoje
              todayDecoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              // Estilo para o dia selecionado
              selectedDecoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay, // Carrega os marcadores de treino
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          );
  }
}
