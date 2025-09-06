import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:sih_project/services/location_service.dart';
import 'package:sih_project/utils/theme_colors.dart';
import 'package:sih_project/widgets/animated_intro.dart';
import 'package:sih_project/widgets/location_card.dart';
import 'package:sih_project/widgets/input_options.dart';
import 'package:sih_project/widgets/recommendation_card.dart';

void main() {
  runApp(const CropApp());
}

class CropApp extends StatefulWidget {
  const CropApp({super.key});

  @override
  State<CropApp> createState() => _CropAppState();
}

class _CropAppState extends State<CropApp> {
  String _locationText = "Fetching location...";
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await getCurrentLocation();
      // Delay for animation effect
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _locationText =
                "Latitude: ${loc["latitude"]!.toStringAsFixed(4)}, Longitude: ${loc["longitude"]!.toStringAsFixed(4)}";
            _locationFetched = true;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = "Could not fetch location.";
          _locationFetched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts
            .interTextTheme(), // Changed to Inter for better readability
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        scaffoldBackgroundColor: backgroundColor,
      ),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.8),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom App Bar with gradient
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedIntro(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.agriculture,
                            color: primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Krishi AI Sahayak",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.1),
                          accentColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Hero Section
                      AnimatedIntro(
                        delay: const Duration(milliseconds: 200),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.eco,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Smart Crop Recommendations",
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Get AI-powered crop suggestions based on your soil conditions and local climate",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Location Card
                      AnimatedIntro(
                        delay: const Duration(milliseconds: 400),
                        child: LocationCard(
                          locationFetched: _locationFetched,
                          locationText: _locationText,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Input Method Section
                      AnimatedIntro(
                        delay: const Duration(milliseconds: 600),
                        child: _buildSectionHeader(
                            "Choose Input Method", Icons.input),
                      ),
                      const SizedBox(height: 15),
                      const AnimatedIntro(
                        delay: Duration(milliseconds: 800),
                        child: InputOptions(),
                      ),

                      const SizedBox(height: 30),

                      // Recommendations Section
                      AnimatedIntro(
                        delay: const Duration(milliseconds: 1000),
                        child: _buildSectionHeader(
                            "AI Recommendations", Icons.psychology),
                      ),
                      const SizedBox(height: 15),
                      const AnimatedIntro(
                        delay: Duration(milliseconds: 1200),
                        child: RecommendationCard(),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
