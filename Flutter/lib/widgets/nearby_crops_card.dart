import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_colors.dart';
import '../providers/recommendation_provider.dart';

class NearbyCropsCard extends StatefulWidget {
  const NearbyCropsCard({super.key});

  @override
  State<NearbyCropsCard> createState() => _NearbyCropsCardState();
}

class _NearbyCropsCardState extends State<NearbyCropsCard> {
  final Map<String, Color> cropColors = {};
  late List<String> gridCrops = [];
  int farmIndex = 0;
  final Random _rand = Random();
  final int totalFields = 36;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<RecommendationProvider>(context);
    final recs = provider.recommendations;

    if (recs.isNotEmpty && gridCrops.isEmpty) {
      _generateGridFromCompetitionAnalysis(
        recs.map((e) => e['crop'] as String).toList(),
        provider.competitionAnalysis,
      );
    }
  }

  void _generateGridFromCompetitionAnalysis(
    List<String> recList,
    String competitionAnalysis,
  ) {
    gridCrops = [];
    Map<String, double> cropWeights =
        _parseCompetitionAnalysis(recList, competitionAnalysis);

    for (int i = 0; i < totalFields; i++) {
      final crop = _getWeightedRandomCrop(recList, cropWeights);
      gridCrops.add(crop);
    }

    final centerStart = 15;
    final centerEnd = 21;
    farmIndex = centerStart + _rand.nextInt(centerEnd - centerStart);

    setState(() {});
  }

  Map<String, double> _parseCompetitionAnalysis(
      List<String> crops, String analysis) {
    Map<String, double> weights = {};
    final lowerAnalysis = analysis.toLowerCase();

    for (String crop in crops) {
      weights[crop] = 1.0;
    }

    for (String crop in crops) {
      final lowerCrop = crop.toLowerCase();

      if (lowerAnalysis.contains(lowerCrop) &&
          (lowerAnalysis.contains("many farmers") ||
              lowerAnalysis.contains("already growing") ||
              lowerAnalysis.contains("high competition"))) {
        weights[crop] = 0.3;
      } else if (lowerAnalysis.contains(lowerCrop) &&
          (lowerAnalysis.contains("less competition") ||
              lowerAnalysis.contains("relatively less") ||
              lowerAnalysis.contains("decent earning"))) {
        weights[crop] = 2.0;
      }

      if (lowerAnalysis.contains(lowerCrop) &&
          !lowerAnalysis.contains("many farmers")) {
        weights[crop] = math.max(weights[crop] ?? 1.0, 1.5);
      }
    }

    return weights;
  }

  String _getWeightedRandomCrop(
      List<String> crops, Map<String, double> weights) {
    double totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
    double randomValue = _rand.nextDouble() * totalWeight;

    double currentWeight = 0.0;
    for (String crop in crops) {
      currentWeight += weights[crop] ?? 1.0;
      if (randomValue <= currentWeight) return crop;
    }

    return crops[_rand.nextInt(crops.length)];
  }

  Color _getColorForCrop(String crop) {
    if (cropColors.containsKey(crop)) return cropColors[crop]!;

    final cropColorMap = {
      'wheat': [Colors.amber.shade600, Colors.orange.shade400],
      'rice': [Colors.green.shade400, Colors.lightGreen.shade500],
      'corn': [Colors.yellow.shade600, Colors.amber.shade500],
      'soybean': [Colors.green.shade600, Colors.teal.shade400],
      'cotton': [Colors.grey.shade300, Colors.blueGrey.shade200],
      'jute': [Colors.brown.shade400, Colors.amber.shade700],
      'coconut': [Colors.green.shade700, Colors.teal.shade600],
      'pigeonpeas': [Colors.orange.shade400, Colors.deepOrange.shade300],
      'apple': [Colors.red.shade400, Colors.pink.shade400],
    };

    Color color;
    final lowerCrop = crop.toLowerCase();
    if (cropColorMap.containsKey(lowerCrop)) {
      final colors = cropColorMap[lowerCrop]!;
      color = colors[_rand.nextInt(colors.length)];
    } else {
      final earthyColors = [
        Colors.green.shade400,
        Colors.brown.shade400,
        Colors.amber.shade500,
        Colors.orange.shade400,
        Colors.lime.shade500,
      ];
      color = earthyColors[_rand.nextInt(earthyColors.length)];
    }

    cropColors[crop] = color;
    return color;
  }

  Widget _buildField(int index) {
    final isFarm = index == farmIndex;
    final crop = isFarm ? "Your Farm" : gridCrops[index];
    final color = isFarm ? Colors.deepOrange.shade400 : _getColorForCrop(crop);

    double width, height;
    if (isFarm) {
      width = 90.0 + _rand.nextInt(15);
      height = 70.0 + _rand.nextInt(15);
    } else {
      final isWide = _rand.nextBool();
      if (isWide) {
        width = 50.0 + _rand.nextInt(25);
        height = 30.0 + _rand.nextInt(15);
      } else {
        width = 30.0 + _rand.nextInt(15);
        height = 40.0 + _rand.nextInt(20);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(isFarm ? 12.0 : 3.0 + _rand.nextInt(6)),
        border: Border.all(
          color: isFarm ? Colors.deepOrange.shade700 : color.withOpacity(0.7),
          width: isFarm ? 2.0 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: isFarm ? 6 : 3,
            offset: Offset(0, isFarm ? 3 : 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isFarm ? "Your\nFarm" : crop,
          style: GoogleFonts.inter(
            fontSize: isFarm ? 10 : 8,
            fontWeight: isFarm ? FontWeight.bold : FontWeight.w500,
            color: Colors.white.withOpacity(isFarm ? 1.0 : 0.9),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recs = Provider.of<RecommendationProvider>(context).recommendations;

    if (recs.isEmpty) {
      return const Center(child: Text("No nearby crops available."));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100.withOpacity(0.2)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map, size: 24, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Nearby Farms",
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              alignment: WrapAlignment.center,
              children: List.generate(gridCrops.length, (index) {
                return _buildField(index);
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Farm distribution based on local competition analysis",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
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
