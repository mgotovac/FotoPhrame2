import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/home_screen.dart';

class FotoPhrame extends StatelessWidget {
  const FotoPhrame({super.key});

  @override
  Widget build(BuildContext context) {
    // Fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      title: 'FotoPhrame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
