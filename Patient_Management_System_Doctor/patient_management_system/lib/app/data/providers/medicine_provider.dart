import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _currentCheckupKey;

  List<Map<String, dynamic>> get medicines => _medicines;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get errorMessage => _errorMessage;

  // Load medicines for a specific checkup
  Future<void> loadMedicines(String patientMobile, String checkupDate) async {
    _currentCheckupKey = 'medicines_${patientMobile}_$checkupDate';
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final medicinesJson = prefs.getString(_currentCheckupKey!);

      if (medicinesJson != null) {
        final List<dynamic> decoded = json.decode(medicinesJson);
        _medicines = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _medicines = [];
      }

      _isInitialLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load medicines';
      _isInitialLoading = false;
      _medicines = [];
      notifyListeners();
    }
  }

  // Add new medicine
  Future<bool> addMedicine(Map<String, dynamic> medicine) async {
    if (_currentCheckupKey == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      _medicines.add(medicine);
      await _saveMedicines();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add medicine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add multiple medicines at once
  Future<bool> addMultipleMedicines(List<Map<String, dynamic>> medicinesList) async {
    if (_currentCheckupKey == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _medicines.addAll(medicinesList);
      await _saveMedicines();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add medicines';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update medicine
  Future<bool> updateMedicine(int index, Map<String, dynamic> medicine) async {
    if (_currentCheckupKey == null || index < 0 || index >= _medicines.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      _medicines[index] = medicine;
      await _saveMedicines();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update medicine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete medicine
  Future<bool> deleteMedicine(int index) async {
    if (_currentCheckupKey == null || index < 0 || index >= _medicines.length) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      _medicines.removeAt(index);
      await _saveMedicines();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete medicine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save medicines to SharedPreferences
  Future<void> _saveMedicines() async {
    if (_currentCheckupKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final medicinesJson = json.encode(_medicines);
    await prefs.setString(_currentCheckupKey!, medicinesJson);
  }

  // Get medicine by index
  Map<String, dynamic>? getMedicine(int index) {
    if (index < 0 || index >= _medicines.length) return null;
    return _medicines[index];
  }

  // Search medicines by name
  List<Map<String, dynamic>> searchMedicines(String query) {
    if (query.isEmpty) return _medicines;
    
    return _medicines.where((medicine) {
      final name = medicine['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
  }

  // Filter medicines by type (Tablet/Syrup)
  List<Map<String, dynamic>> filterByType(String type) {
    return _medicines.where((medicine) {
      return medicine['type']?.toString().toLowerCase() == type.toLowerCase();
    }).toList();
  }

  // Get medicines count
  int get medicinesCount => _medicines.length;

  // Check if medicines list is empty
  bool get isEmpty => _medicines.isEmpty;

  // Check if medicines list is not empty
  bool get isNotEmpty => _medicines.isNotEmpty;

  // Clear medicines (for new checkup or logout)
  void clearMedicines() {
    _medicines = [];
    _currentCheckupKey = null;
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

  // Set medicines directly (useful for initial setup)
  void setMedicines(List<Map<String, dynamic>> medicinesList) {
    _medicines = medicinesList;
    notifyListeners();
  }

  // Get total number of tablets
  int get tabletsCount {
    return _medicines.where((m) => m['type'] == 'Tablet').length;
  }

  // Get total number of syrups
  int get syrupsCount {
    return _medicines.where((m) => m['type'] == 'Syrup').length;
  }

  // Get medicines grouped by timing
  Map<String, List<Map<String, dynamic>>> getMedicinesByTiming() {
    return {
      'morning': _medicines.where((m) => m['morning'] == true).toList(),
      'afternoon': _medicines.where((m) => m['afternoon'] == true).toList(),
      'evening': _medicines.where((m) => m['evening'] == true).toList(),
    };
  }

  // Get medicines by meal timing
  Map<String, List<Map<String, dynamic>>> getMedicinesByMealTiming() {
    return {
      'before': _medicines.where((m) => m['mealTiming'] == 'Before').toList(),
      'after': _medicines.where((m) => m['mealTiming'] == 'After').toList(),
    };
  }

  // Export medicines data (for sharing or printing)
  String exportMedicinesData() {
    if (_medicines.isEmpty) return 'No medicines prescribed';

    final buffer = StringBuffer();
    buffer.writeln('Prescribed Medicines:\n');

    for (int i = 0; i < _medicines.length; i++) {
      final medicine = _medicines[i];
      buffer.writeln('${i + 1}. ${medicine['name']} (${medicine['type']})');
      buffer.writeln('   Duration: ${medicine['days']} days');
      
      final timings = <String>[];
      if (medicine['morning'] == true) timings.add('Morning');
      if (medicine['afternoon'] == true) timings.add('Afternoon');
      if (medicine['evening'] == true) timings.add('Evening');
      buffer.writeln('   Timing: ${timings.join(', ')}');
      buffer.writeln('   ${medicine['mealTiming']} Meal');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}