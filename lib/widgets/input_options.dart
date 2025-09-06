import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../utils/theme_colors.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import 'recommendation_provider.dart';

class InputOptions extends StatelessWidget {
  const InputOptions({super.key});

  Future<Map<String, dynamic>> fetchCropRecommendations({
    required double lat,
    required double long,
    required int n,
    required int p,
    required int k,
    required double ph,
    int topK = 5,
  }) async {
    final url = Uri.parse("https://sih25-farmers.onrender.com/recommend_crops");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "lat": lat,
        "long": long,
        "N": n,
        "P": p,
        "K": k,
        "Ph": ph,
        "top_k": topK,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch recommendations: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                context: context,
                icon: Icons.sensors_outlined,
                label: "IoT Sensors",
                subtitle: "Automated data",
                color: primaryColor,
                onTap: () {
                  _showFeatureDialog(
                    context,
                    "IoT Sensor Integration",
                    "Connect with smart sensors to automatically collect soil data including NPK levels, pH, moisture, and temperature.",
                    Icons.sensors,
                    "Coming Soon",
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOptionCard(
                context: context,
                icon: Icons.edit_note_outlined,
                label: "Manual Entry",
                subtitle: "Enter values",
                color: accentColor,
                onTap: () => _showManualInputDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    String status,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () {
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(status),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(BuildContext context) {
    final nController = TextEditingController();
    final pController = TextEditingController();
    final kController = TextEditingController();
    final phController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter Soil Data"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEnhancedTextField(nController, "Nitrogen (N)", "", Icons.eco),
            const SizedBox(height: 8),
            _buildEnhancedTextField(
                pController, "Phosphorus (P)", "", Icons.water_drop),
            const SizedBox(height: 8),
            _buildEnhancedTextField(
                kController, "Potassium (K)", "", Icons.grain),
            const SizedBox(height: 8),
            _buildEnhancedTextField(
                phController, "Soil pH", "0-14", Icons.analytics),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final n = int.tryParse(nController.text) ?? 0;
              final p = int.tryParse(pController.text) ?? 0;
              final k = int.tryParse(kController.text) ?? 0;
              final ph = double.tryParse(phController.text) ?? 0;

              if (n == 0 || p == 0 || k == 0 || ph == 0) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill all fields properly")),
                  );
                }
                return;
              }

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) _showLoadingDialog(context);

              try {
                final loc = await getCurrentLocation();
                final result = await fetchCropRecommendations(
                  lat: loc["latitude"]!,
                  long: loc["longitude"]!,
                  n: n,
                  p: p,
                  k: k,
                  ph: ph,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
// crops data from API
                final crops = (result["recommended_crops"] as List).join(", ");
                context
                    .read<RecommendationProvider>()
                    .setRecommendations(crops);
// weather data from API
                final weatherData =
                    result["weather_data"] as Map<String, dynamic>;
                context.read<RecommendationProvider>().setWeather(weatherData);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Get Recommendations"),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField(
    TextEditingController controller,
    String label,
    String unit,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );
  }
}
