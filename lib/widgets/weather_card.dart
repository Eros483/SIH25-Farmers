import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import '../utils/theme_colors.dart';
import '../providers/recommendation_provider.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<RecommendationProvider>().weather;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100.withOpacity(0.2)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.cloud, size: 24, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Weather Conditions",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildWeatherState(weather),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    return Column(
      children: [
        const Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          "Awaiting Data",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Weather details will appear once you fetch recommendations.",
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeatherState(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildWeatherRow(
            Icons.thermostat, "Temperature", "${data["temperature_c"]} °C"),
        const SizedBox(height: 12),
        _buildWeatherRow(Icons.water_drop, "Humidity",
            "${data["relative_humidity_percent"]}%"),
        const SizedBox(height: 12),
        _buildWeatherRow(Icons.cloudy_snowing, "Annual Rainfall",
            "${data["annual_precip_mm"]} mm"),
      ],
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }
}
