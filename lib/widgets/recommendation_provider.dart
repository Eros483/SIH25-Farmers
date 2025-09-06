import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  String? _recommendations;
  Map<String, dynamic>? _weather;

  String? get recommendations => _recommendations;
  Map<String, dynamic>? get weather => _weather;

  void setRecommendations(String recs) {
    _recommendations = recs;
    notifyListeners();
  }

  void setWeather(Map<String, dynamic> data) {
    _weather = data;
    notifyListeners();
  }
}
