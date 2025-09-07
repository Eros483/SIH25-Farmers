import 'package:flutter/material.dart';
import 'package:sih_project/widgets/location_card.dart';
import 'package:sih_project/widgets/input_options.dart';
import 'package:sih_project/widgets/recommendation_card.dart';
import 'package:sih_project/widgets/weather_card.dart';
import 'package:sih_project/widgets/floating_action_menu.dart';
import 'package:sih_project/widgets/section_header.dart';
import 'package:sih_project/widgets/animated_intro.dart';
import 'package:sih_project/services/location_service.dart';
import 'chatbot_page.dart';
import 'govt_verified_wholesaler.dart';
import 'package:sih_project/utils/theme_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sih_project/widgets/nearby_crops_card.dart';
import 'package:sih_project/widgets/competition_analysis_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _locationText = "Fetching location...";
  bool _locationFetched = false;

  late AnimationController _menuController;
  late AnimationController _rotationController;
  late Animation<double> _menuAnimation;
  late Animation<double> _rotationAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _setupAnimations();
  }

  void _setupAnimations() {
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation =
        CurvedAnimation(parent: _menuController, curve: Curves.easeInOut);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await getCurrentLocation();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _locationText =
                "Lat: ${loc['latitude']!.toStringAsFixed(4)}, Lon: ${loc['longitude']!.toStringAsFixed(4)}";
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

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    _isMenuOpen ? _menuController.forward() : _menuController.reverse();
    _isMenuOpen ? _rotationController.forward() : _rotationController.reverse();
  }

  void _navigateToChatBot(BuildContext context) {
    _toggleMenu();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ChatBotPage()));
  }

  void _navigateToVerifiedPage(BuildContext context) {
    _toggleMenu();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GovtVerifiedWholesalerPage()));
  }

  @override
  void dispose() {
    _menuController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainContent(),
          FloatingActionMenu(
            menuAnimation: _menuAnimation,
            rotationAnimation: _rotationAnimation,
            isMenuOpen: _isMenuOpen,
            toggleMenu: _toggleMenu,
            navigateToChatBot: () => _navigateToChatBot(context),
            navigateToVerifiedPage: () => _navigateToVerifiedPage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
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
                  const Icon(Icons.agriculture, color: primaryColor, size: 24),
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
                    Colors.green.withOpacity(0.05)
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeroCard(),
                const SizedBox(height: 30),
                AnimatedIntro(
                  delay: const Duration(milliseconds: 400),
                  child: LocationCard(
                    locationFetched: _locationFetched,
                    locationText: _locationText,
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedIntro(
                  delay: const Duration(milliseconds: 600),
                  child: SectionHeader(
                      title: "Choose Input Method", icon: Icons.input),
                ),
                const SizedBox(height: 15),
                const InputOptions(),
                const SizedBox(height: 30),
                AnimatedIntro(
                  delay: const Duration(milliseconds: 1000),
                  child: SectionHeader(
                      title: "AI Recommendations", icon: Icons.psychology),
                ),
                const SizedBox(height: 15),
                const CompetitionAnalysisWidget(),
                const RecommendationCard(),
                const NearbyCropsCard(),
                const WeatherCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHeroCard() {
    return AnimatedIntro(
      delay: const Duration(milliseconds: 200),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.8), primaryColor],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                "Smart Crop Recommendations",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _navigateToChatBot(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Ask AI Assistant",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
