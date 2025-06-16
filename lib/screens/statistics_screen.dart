import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:colorfeel/services/mood_storage.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  Map<Color, int> _moodCounts = {};
  Color? _mostFrequentMood;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _loadMoodStats();
  }

  Future<void> _loadMoodStats() async {
    final now = DateTime.now();
    final start = _selectedPeriod == 'week'
        ? now.subtract(const Duration(days: 6))
        : DateTime(now.year, now.month, 1);

    final counts = await MoodStorage.getMoodCountInRange(start, now);
    final most = await MoodStorage.getMostFrequentMood(start, now);

    if (!mounted) return;
    setState(() {
      _moodCounts = counts;
      _mostFrequentMood = most;
    });
  }

  String get _periodLabel =>
      _selectedPeriod == 'week' ? '이번 주' : '이번 달';

  Widget _buildReport() {
    if (_moodCounts.isEmpty || _mostFrequentMood == null) {
      return Text(
        '$_periodLabel 동안 기록이 없습니다.',
        style: GoogleFonts.poppins(fontSize: 16),
      );
    }
    final details =
    MoodStorage.moodDetailsByValue[_mostFrequentMood!.value];
    final emoji = details?['emoji'] as String? ?? '';
    final label = details?['label'] as String? ?? '';
    return Text(
      '$_periodLabel 주로 $emoji $label 를 느꼈어요!',
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = _moodCounts.values.fold<int>(0, (a, b) => a + b);
    return _moodCounts.entries.map((entry) {
      final count = entry.value;
      final percent = total == 0 ? 0.0 : (count / total) * 100;
      return PieChartSectionData(
        color: entry.key,
        value: count.toDouble(),
        title: '${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle:
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Future<void> _shareStats() async {
    // RepaintBoundary 를 찾아 이미지로 변환
    final boundary = _boundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // 임시 디렉토리에 파일로 저장
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/statistics.png');
    await file.writeAsBytes(pngBytes);

    // 공유
    await Share.shareFiles([file.path], text: '나의 감정 통계입니다!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStats,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _boundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 선택
              DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('이번 주')),
                  DropdownMenuItem(value: 'month', child: Text('이번 달')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedPeriod = v);
                    _loadMoodStats();
                  }
                },
              ),
              const SizedBox(height: 16),

              // 리포트 텍스트
              _buildReport(),
              const SizedBox(height: 24),

              // 파이 차트
              if (_moodCounts.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 리스트
              Expanded(
                child: _moodCounts.isEmpty
                    ? Center(
                  child: Text(
                    '아직 감정 기록이 없습니다.',
                    style: GoogleFonts.poppins(),
                  ),
                )
                    : ListView(
                  children: _moodCounts.entries.map((entry) {
                    final info = MoodStorage
                        .moodDetailsByValue[entry.key.value];
                    final emoji = info?['emoji'] as String? ?? '';
                    final label = info?['label'] as String? ?? '';
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: entry.key),
                      title: Text('$emoji $label'),
                      trailing: Text('${entry.value}회'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
