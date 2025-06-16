import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodStorage {
  // 기본 감정 데이터
  static final Map<int, Map<String, dynamic>> moodDetailsByValue = {
    Colors.yellow.value: {'emoji': '😊', 'label': '행복'},
    Colors.grey.value: {'emoji': '😐', 'label': '무난'},
    Colors.blue.value: {'emoji': '😢', 'label': '슬픔'},
    Colors.red.value: {'emoji': '😠', 'label': '분노'},
    Colors.purple.value: {'emoji': '😴', 'label': '피곤'},
    Colors.pink.value: {'emoji': '💖', 'label': '사랑'},
  };

  static String getDateKey(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  // 기분 저장 (색상만)
  static Future<void> saveMood(DateTime date, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getDateKey(date);
    final value = jsonEncode({'color': color.value});
    await prefs.setString(key, value);
  }

  // 기분 저장 (색상 + 메모)
  static Future<void> saveMoodWithMemo(DateTime date, Color color, String memo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getDateKey(date);
    final value = jsonEncode({'color': color.value, 'memo': memo});
    await prefs.setString(key, value);
  }

  // 기분 불러오기 (Map<String, Color>)
  static Future<Map<String, Color>> loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('-')).toList();

    Map<String, Color> result = {};
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value == null) continue;

      try {
        final decoded = jsonDecode(value);
        if (decoded is Map && decoded['color'] != null) {
          result[key] = Color(decoded['color']);
        }
      } catch (_) {}
    }
    return result;
  }

  // 기분 + 메모 불러오기
  static Future<Map<String, Map<String, dynamic>>> loadMoodsWithMemo() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('-')).toList();

    Map<String, Map<String, dynamic>> result = {};

    for (final key in keys) {
      final value = prefs.getString(key);
      if (value == null) continue;

      try {
        final decoded = jsonDecode(value);
        if (decoded is Map && decoded['color'] != null) {
          final colorInt = decoded['color'];
          final memo = decoded['memo'] ?? '';
          result[key] = {
            'color': Color(colorInt),
            'memo': memo,
          };
        }
      } catch (e) {
        continue;
      }
    }

    return result;
  }

  // 감정 카운트 (주간/월간 통계용)
  static Future<Map<Color, int>> getMoodCountInRange(DateTime start, DateTime end) async {
    final moods = await loadMoods();
    Map<Color, int> count = {};

    moods.forEach((key, color) {
      final date = DateTime.tryParse(key);
      if (date != null && !date.isBefore(start) && !date.isAfter(end)) {
        count[color] = (count[color] ?? 0) + 1;
      }
    });

    return count;
  }

  // 가장 많이 선택된 감정 찾기
  static Future<Color?> getMostFrequentMood(DateTime start, DateTime end) async {
    final counts = await getMoodCountInRange(start, end);
    if (counts.isEmpty) return null;

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
