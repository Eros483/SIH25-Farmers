import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic> _weather = {};

  List<Map<String, dynamic>> get recommendations => _recommendations;
  Map<String, dynamic> get weather => _weather;

  void setRecommendations(List<Map<String, dynamic>> crops) {
    _recommendations = crops;
    notifyListeners();
  }

  void setWeather(Map<String, dynamic> weatherData) {
    _weather = weatherData;
    notifyListeners();
  }
}
