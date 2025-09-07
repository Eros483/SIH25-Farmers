import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic> _weather = {};
  String _competitionAnalysis = "";
  String _selectedLanguage = "english";

  List<Map<String, dynamic>> get recommendations => _recommendations;
  Map<String, dynamic> get weather => _weather;
  String get competitionAnalysis => _competitionAnalysis;
  String get selectedLanguage => _selectedLanguage;

  void setCompetitionAnalysis(String analysis) {
    _competitionAnalysis = analysis;
    notifyListeners();
  }

  void setRecommendations(List<Map<String, dynamic>> crops) {
    _recommendations = crops;
    notifyListeners();
  }

  void setWeather(Map<String, dynamic> weatherData) {
    _weather = weatherData;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  // Helper method to check if current language is RTL or needs special formatting
  bool get isNonEnglish => _selectedLanguage != "english";

  bool get isBengali => _selectedLanguage == "bengali";

  bool get isHindi => _selectedLanguage == "hindi";
}
