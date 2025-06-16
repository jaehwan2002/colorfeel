import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ColorFeelApp());
}

class ColorFeelApp extends StatelessWidget {
  const ColorFeelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorFeel',
      debugShowCheckedModeBanner: false,

      // 라이트 테마
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ).apply(bodyColor: Colors.black),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          onBackground: Colors.black,
        ),
      ),

      // 다크 테마
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ).copyWith(onBackground: Colors.white),
      ),

      // 시스템 설정에 따라 자동 전환
      themeMode: ThemeMode.system,

      // ★ 첫 화면을 SplashScreen()으로
      home: SplashScreen(),
    );
  }
}
