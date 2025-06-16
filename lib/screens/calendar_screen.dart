import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:colorfeel/services/mood_storage.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  Map<String, Color> _moods = {};

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final loaded = await MoodStorage.loadMoods();
    if (!mounted) return;
    setState(() => _moods = loaded);
  }

  Widget _buildMarker(DateTime day) {
    final key = MoodStorage.getDateKey(day);
    final moodColor = _moods[key];
    if (moodColor == null) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: moodColor,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('감정 캘린더')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          onPageChanged: (newFocused) {
            setState(() => _focusedDay = newFocused);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${day.day}'),
                  _buildMarker(day),
                ],
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildMarker(day),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
