import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String demoEmail = 'demo@medtrack.com';
  static const String demoPassword = 'demo123';
  static const String demoName = 'Dr. Rajesh Kumar';
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userName;
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get userEmail => _userEmail;

  String? get userName => _userName;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  // Set loader
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Load user if already logged in
  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _token = prefs.getString('token');
      _userEmail = prefs.getString('email');
      _userName = prefs.getString('userName');
      _isLoggedIn = isLoggedIn && _token != null;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Signup logic...
  Future<bool> signUpUser(String name, String email, String password, {String degree = '', String phoneNo = ''}) async {
    setLoading(true);
    _errorMessage = null;
    
    try {
      final response = await ApiService.post('doctor/register', {
        'fullname': name,
        'email': email,
        'password': password,
        'degree': degree,
        'phoneNo': phoneNo,
      });

      if (response != null && response['doctorId'] != null) {
        // Auto-login after successful registration
        final loggedIn = await login(email, password);
        setLoading(false);
        return loggedIn;
      }
      _errorMessage = 'Registration failed';
      setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
      setLoading(false);
      return false;
    }
  }

  //Login logic...
  Future<bool> login(String email, String password) async {
    setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.post('doctor/login', {
        'email': email,
        'password': password,
      });

      _token = response['token'];
      final doctor = response['doctor'];

      if (_token == null || doctor == null) {
        _errorMessage = 'Invalid server response';
        setLoading(false);
        return false;
      }

      _userEmail = doctor['email'];
      _userName = doctor['fullname'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('email', _userEmail!);
      await prefs.setString('userName', _userName!);
      await prefs.setBool('isLoggedIn', true);

      setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
      
      setLoading(false);
      return false;
    }
  }

  // Logout Logic...
  Future<void> logOutUser() async {
    setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _userName = null;
      _userEmail = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _token = null;
      
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      notifyListeners();
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
