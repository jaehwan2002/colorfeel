import 'package:flutter/material.dart';
import 'package:colorfeel/services/mood_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  Map<String, Map<String, dynamic>> _history = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await MoodStorage.loadMoodsWithMemo();
    final sorted = Map.fromEntries(
      data.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    if (!mounted) return;
    setState(() => _history = sorted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('감정 히스토리')),
      body: _history.isEmpty
          ? const Center(child: Text('기록된 감정이 없습니다.'))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (ctx, i) {
          final entry = _history.entries.elementAt(i);
          final date = entry.key;
          final data = entry.value;
          final color = data['color'] as Color;
          final memo = data['memo'] as String;
          final emoji = MoodStorage.moodDetailsByValue[color.value]?['emoji'] ?? '';
          final label = MoodStorage.moodDetailsByValue[color.value]?['label'] ?? '';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(emoji),
            ),
            title: Text('$date – $label'),
            subtitle: memo.isNotEmpty ? Text(memo) : null,
          );
        },
      ),
    );
  }
}
