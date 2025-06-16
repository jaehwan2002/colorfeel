import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:colorfeel/screens/calendar_screen.dart';
import 'package:colorfeel/screens/statistics_screen.dart';
import 'package:colorfeel/screens/history_screen.dart';
import 'package:colorfeel/services/mood_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color? selectedColor;
  int streakDays = 0;
  String dailyPhrase = '';

  // ────── 여기에 추가 ──────
  int recordedThisMonth = 0;
  int daysSoFar = 0;
  double monthProgress = 0.0;
  // ───────────────────────

  final List<String> phrases = const [
    '오늘이 당신에게 특별한 하루가 되길 바라요.',
    '작은 기쁨이 모여 큰 행복이 됩니다.',
    '지금 느끼는 감정도 소중한 순간입니다.',
    '한 걸음 더 나아가면 새로운 내일이 기다립니다.',
    '당신의 오늘이 빛나길 응원해요.',
    '감정을 기록하는 것만으로도 용기입니다.',
    '숨 고르고, 오늘의 색을 골라보세요.',
    '하루의 마무리에 감사 한 스푼을 더해보세요.',
    '오늘도 당신은 잘 해내고 있어요.',
    '감정은 지나가는 구름, 기록은 남는 발자국.'
  ];

  final List<Map<String, dynamic>> moods = const [
    {'emoji': '😊', 'color': Colors.yellow, 'label': '행복'},
    {'emoji': '😐', 'color': Colors.grey,   'label': '무난'},
    {'emoji': '😢', 'color': Colors.blue,   'label': '슬픔'},
    {'emoji': '😠', 'color': Colors.red,    'label': '분노'},
    {'emoji': '😴', 'color': Colors.purple, 'label': '피곤'},
    {'emoji': '💖', 'color': Colors.pink,   'label': '사랑'},
  ];

  @override
  void initState() {
    super.initState();
    _selectDailyPhrase();
    _loadTodayMood();
    _loadStreak();
    _loadMonthlyProgress(); // ───── 여기에 호출 추가
  }

  void _selectDailyPhrase() {
    final now = DateTime.now();
    final idx = (now.month * 31 + now.day) % phrases.length;
    dailyPhrase = phrases[idx];
  }

  void _loadTodayMood() async {
    final saved = await MoodStorage.loadMoods();
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    if (mounted && saved.containsKey(todayKey)) {
      setState(() => selectedColor = saved[todayKey]);
    }
  }

  void _loadStreak() async {
    final saved = await MoodStorage.loadMoods();
    final recordedDates = saved.keys
        .map((k) => DateTime.parse(k))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    int streak = 0;
    DateTime day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);

    while (recordedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    if (mounted) {
      setState(() => streakDays = streak);
    }
  }

  // ────── 월간 진행도 계산 함수 추가 ──────
  void _loadMonthlyProgress() async {
    final saved = await MoodStorage.loadMoods();
    final now = DateTime.now();

    // 1일부터 오늘까지 날짜 문자열 리스트 생성
    final allDays = List.generate(now.day, (i) {
      final d = DateTime(now.year, now.month, i + 1);
      return d.toIso8601String().split('T')[0];
    });

    // 저장된 키와 비교
    recordedThisMonth = allDays.where((k) => saved.containsKey(k)).length;
    daysSoFar = allDays.length;
    monthProgress = daysSoFar > 0
        ? recordedThisMonth / daysSoFar
        : 0.0;

    if (mounted) setState(() {});
  }
  // ───────────────────────────────────────

  Future<void> _saveMoodWithMemo(Color color) async {
    final memoController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('메모 추가'),
        content: TextField(
          controller: memoController,
          decoration: InputDecoration(
            hintText: '오늘의 기분을 간단히 메모해보세요',
            hintStyle: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text('취소', style: Theme.of(context).textTheme.bodyLarge),
          ),
          TextButton(
            onPressed: () async {
              final memo = memoController.text;
              await MoodStorage.saveMoodWithMemo(
                  DateTime.now(), color, memo);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => selectedColor = color);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('기분이 저장되었습니다! 🎉',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                ),
              );
              _loadStreak();
              _loadMonthlyProgress(); // 저장 후에도 갱신
            },
            child:
            Text('저장', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
    );
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 기분'),
        actions: [
          IconButton(
              icon: const Icon(Icons.list),
              onPressed: _navigateToHistory),
          IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: _navigateToStatistics),
          IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _navigateToCalendar),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 상단: 안내 문구 + 감정 선택 ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 기분을 색으로 골라주세요',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((m) {
                    final c = m['color'] as Color;
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => _saveMoodWithMemo(c),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(width: 4, color: borderColor)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            m['emoji'] as String,
                            style: TextStyle(
                              fontSize: 30,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // ─── 하단: 월간 진행도 + 문구 + 스티크 ───
            Column(
              children: [
                // 이번 달 기록 진행도
                Text(
                  '이번 달 기록: $recordedThisMonth/$daysSoFar 일',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: monthProgress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // 오늘의 문구
                Text(
                  dailyPhrase,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color,
                  ),
                ),
                const SizedBox(height: 12),

                // 연속 기록
                Text(
                  streakDays > 0
                      ? '연속 기록: $streakDays일'
                      : '아직 기록이 없습니다',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
