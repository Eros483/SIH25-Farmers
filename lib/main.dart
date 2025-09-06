import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recommendation_provider.dart';
import 'app.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RecommendationProvider(),
      child: const CropApp(),
    ),
  );
}
