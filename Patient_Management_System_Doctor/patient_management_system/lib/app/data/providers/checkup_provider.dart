import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckupProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _checkups = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentPatientKey;

  List<Map<String, dynamic>> get checkups => _checkups;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Load checkups for specific patient
  Future<void> loadCheckups(
    String patientMobile,
    String clinicName,
    String userEmail,
  ) async {
    _currentPatientKey = 'checkups_${userEmail}_${clinicName}_$patientMobile';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final checkupsJson = prefs.getString(_currentPatientKey!);

      if (checkupsJson != null) {
        final List<dynamic> decoded = json.decode(checkupsJson);
        _checkups = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _checkups = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load checkups';
      _isLoading = false;
      _checkups = [];
      notifyListeners();
    }
  }

  // Add new checkup
  Future<bool> addCheckup(Map<String, dynamic> checkup) async {
    if (_currentPatientKey == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _checkups.add(checkup);
      await _saveCheckups();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add checkup';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save checkups to SharedPreferences
  Future<void> _saveCheckups() async {
    if (_currentPatientKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final checkupsJson = json.encode(_checkups);
    await prefs.setString(_currentPatientKey!, checkupsJson);
  }

  // Clear checkups
  void clearCheckups() {
    _checkups = [];
    _currentPatientKey = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
