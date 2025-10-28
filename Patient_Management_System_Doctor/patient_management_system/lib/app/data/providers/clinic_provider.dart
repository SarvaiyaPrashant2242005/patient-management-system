import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicProvider extends ChangeNotifier {
  List<Map<String, String>> _clinics = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentUserEmail;

  List<Map<String, String>> get clinics => _clinics;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load clinics for specific user
  Future<void> loadClinics(String userEmail) async {
    _currentUserEmail = userEmail;
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final key = 'clinics_$userEmail';
      final clinicsJson = prefs.getString(key);

      if (clinicsJson != null) {
        final List<dynamic> decoded = json.decode(clinicsJson);
        _clinics = decoded.map((e) => Map<String, String>.from(e)).toList();
      } else {
        _clinics = [];
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load clinics';
      _isInitialLoading = false;
      _clinics = [];
      notifyListeners();
    }
  }

  // Add new clinic
  Future<bool> addClinic(Map<String, String> clinic) async {
    if (_currentUserEmail == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _clinics.add(clinic);
      await _saveClinics();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add clinic';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update clinic
  Future<bool> updateClinic(int index, Map<String, String> clinic) async {
    if (_currentUserEmail == null || index < 0 || index >= _clinics.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _clinics[index] = clinic;
      await _saveClinics();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update clinic';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete clinic
  Future<bool> deleteClinic(int index) async {
    if (_currentUserEmail == null || index < 0 || index >= _clinics.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _clinics.removeAt(index);
      await _saveClinics();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete clinic';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save clinics to SharedPreferences
  Future<void> _saveClinics() async {
    if (_currentUserEmail == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'clinics_$_currentUserEmail';
    final clinicsJson = json.encode(_clinics);
    await prefs.setString(key, clinicsJson);
  }

  // Clear clinics (for logout)
  void clearClinics() {
    _clinics = [];
    _currentUserEmail = null;
    _isLoading = false;
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}