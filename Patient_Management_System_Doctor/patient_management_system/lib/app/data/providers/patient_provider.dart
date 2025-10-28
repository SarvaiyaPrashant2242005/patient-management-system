import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentClinicKey;

  List<Map<String, dynamic>> get patients => _patients;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load patients for specific clinic
  Future<void> loadPatients(String clinicName, String userEmail) async {
    _currentClinicKey = 'patients_${userEmail}_$clinicName';
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final patientsJson = prefs.getString(_currentClinicKey!);

      if (patientsJson != null) {
        final List<dynamic> decoded = json.decode(patientsJson);
        _patients = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _patients = [];
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load patients';
      _isInitialLoading = false;
      _patients = [];
      notifyListeners();
    }
  }

  // Add new patient
  Future<bool> addPatient(Map<String, dynamic> patient) async {
    if (_currentClinicKey == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _patients.add(patient);
      await _savePatients();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add patient';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update patient
  Future<bool> updatePatient(int index, Map<String, dynamic> patient) async {
    if (_currentClinicKey == null || index < 0 || index >= _patients.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _patients[index] = patient;
      await _savePatients();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update patient';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete patient
  Future<bool> deletePatient(int index) async {
    if (_currentClinicKey == null || index < 0 || index >= _patients.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _patients.removeAt(index);
      await _savePatients();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete patient';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save patients to SharedPreferences
  Future<void> _savePatients() async {
    if (_currentClinicKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final patientsJson = json.encode(_patients);
    await prefs.setString(_currentClinicKey!, patientsJson);
  }

  // Clear patients (for logout or clinic change)
  void clearPatients() {
    _patients = [];
    _currentClinicKey = null;
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