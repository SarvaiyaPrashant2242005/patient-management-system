import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentProvider extends ChangeNotifier {
  // Reactive state
  bool _loading = false;
  String? _error;

  String? _patientId;
  String _patientName = 'Patient';
  String _doctorName = 'Doctor';

  double _openingBalance = 0;
  double _currentPayment = 0; // today's charges (from latest prescription or passed-in)
  double _amountPayingToday = 0;

  // Getters
  bool get loading => _loading;
  String? get error => _error;

  String? get patientId => _patientId;
  String get patientName => _patientName;
  String get doctorName => _doctorName;

  double get openingBalance => _openingBalance;
  double get currentPayment => _currentPayment;
  double get amountPayingToday => _amountPayingToday;
  double get totalPayment => _openingBalance + _currentPayment;
  double get remainingBalance {
    final r = totalPayment - _amountPayingToday;
    return r < 0 ? 0 : r;
  }

  Future<void> loadForPatient({
    required Map<String, dynamic> patient,
    required String doctorName,
    double currentCharges = 0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _patientId = (patient['mobile'] ?? patient['id'] ?? '').toString();
      _patientName = (patient['name'] ?? 'Patient').toString();
      _doctorName = doctorName.isNotEmpty ? doctorName : 'Doctor';
      _currentPayment = currentCharges;

      final prefs = await SharedPreferences.getInstance();
      final balStr = _patientId == null ? null : prefs.getString('balance_$_patientId');
      _openingBalance = balStr != null ? double.tryParse(balStr) ?? 0 : 0;

      // Reset amount paying today on load
      _amountPayingToday = 0;
      _error = null;
    } catch (e) {
      _error = 'Failed to load payment info';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setAmountPayingToday(String value) {
    final v = double.tryParse(value.trim()) ?? 0;
    _amountPayingToday = v;
    notifyListeners();
  }

  Future<bool> confirmPayment() async {
    if (_patientId == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final newBalance = remainingBalance;

      // Persist new balance
      await prefs.setString('balance_$_patientId', newBalance.toStringAsFixed(2));

      // Append history
      final historyKey = 'payments_$_patientId';
      final entry = {
        'date': DateTime.now().toIso8601String(),
        'openingBalance': _openingBalance,
        'currentPayment': _currentPayment,
        'amountPaid': _amountPayingToday,
        'remainingBalance': newBalance,
        'doctorName': _doctorName,
      };
      final raw = prefs.getString(historyKey);
      final list = raw != null ? List<Map<String, dynamic>>.from(json.decode(raw)) : <Map<String, dynamic>>[];
      list.add(entry);
      await prefs.setString(historyKey, json.encode(list));

      // After success: update in-memory openingBalance and clear currentPayment/amountPaying
      _openingBalance = newBalance;
      _currentPayment = 0;
      _amountPayingToday = 0;

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Payment failed';
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    if (_patientId == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('payments_$_patientId');
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(raw));
    } catch (_) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
