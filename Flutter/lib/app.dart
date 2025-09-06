import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'utils/theme_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CropApp extends StatelessWidget {
  const CropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        scaffoldBackgroundColor: backgroundColor,
      ),
      home: const HomePage(),
    );
  }
}
