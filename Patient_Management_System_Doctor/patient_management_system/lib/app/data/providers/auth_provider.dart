import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String demoEmail = 'demo@medtrack.com';
  static const String demoPassword = 'demo123';
  static const String demoName = 'Dr. Rajesh Kumar';
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userName;
  String? _userDegree;
  String? _userPhone;
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get userEmail => _userEmail;

  String? get userName => _userName;

  String? get userDegree => _userDegree;

  String? get userPhone => _userPhone;

  bool get isLoggedIn => _isLoggedIn;

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
      
      if (isLoggedIn) {
        _userEmail = prefs.getString('email');
        _userName = prefs.getString('userName');
        _userDegree = prefs.getString('degree');
        _userPhone = prefs.getString('phone');
        _isLoggedIn = _userEmail != null && _userName != null;
      } else {
        _isLoggedIn = false;
      }
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Signup logic...
  Future<bool> signUpUser(
    String name,
    String email,
    String password, {
    String? degree,
    String? phone,
  }) async {
    setLoading(true);
    _errorMessage = null;
    
    try {
      // Simulate network delay for demo
      await Future.delayed(const Duration(seconds: 1));
      
      final prefs = await SharedPreferences.getInstance();

      // Check if user already exists
      final existingEmail = prefs.getString('email');
      if (existingEmail != null && existingEmail == email) {
        _errorMessage = "User with this email already exists";
        _isLoggedIn = false;
        setLoading(false);
        return false;
      }
      
      // Save user data
      await prefs.setString('userName', name);
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      if (degree != null && degree.isNotEmpty) {
        await prefs.setString('degree', degree);
      }
      if (phone != null && phone.isNotEmpty) {
        await prefs.setString('phone', phone);
      }
      await prefs.setBool('isLoggedIn', true);

      _userEmail = email;
      _userName = name;
      _userDegree = degree;
      _userPhone = phone;
      _errorMessage = null;
      _isLoggedIn = true;
      
      setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Sign up failed. Please try again.";
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
      // Simulate network delay for demo
      await Future.delayed(const Duration(seconds: 1));
      
      final prefs = await SharedPreferences.getInstance();
      
      // Check demo credentials first
      if (email == demoEmail && password == demoPassword) {
        await prefs.setString('userName', demoName);
        await prefs.setString('email', demoEmail);
        await prefs.setBool('isLoggedIn', true);
        
        _userEmail = demoEmail;
        _userName = demoName;
        _isLoggedIn = true;
        _errorMessage = null;
        
        setLoading(false);
        return true;
      }
      
      // Check saved credentials
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      final savedName = prefs.getString('userName');
      final savedDegree = prefs.getString('degree');
      final savedPhone = prefs.getString('phone');

      if (email == savedEmail && password == savedPassword) {
        await prefs.setBool('isLoggedIn', true);
        
        _userEmail = savedEmail;
        _userName = savedName;
        _userDegree = savedDegree;
        _userPhone = savedPhone;
        _isLoggedIn = true;
        _errorMessage = null;
        
        setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _isLoggedIn = false;
        
        setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
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
      await prefs.setBool('isLoggedIn', false);

      _userName = null;
      _userEmail = null;
      _userDegree = null;
      _userPhone = null;
      _isLoggedIn = false;
      _errorMessage = null;
      
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

  // Update profile data
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? degree,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (name != null) {
        await prefs.setString('userName', name);
        _userName = name;
      }
      
      if (email != null) {
        await prefs.setString('email', email);
        _userEmail = email;
      }
      
      if (degree != null) {
        if (degree.isEmpty) {
          await prefs.remove('degree');
          _userDegree = null;
        } else {
          await prefs.setString('degree', degree);
          _userDegree = degree;
        }
      }
      
      if (phone != null) {
        if (phone.isEmpty) {
          await prefs.remove('phone');
          _userPhone = null;
        } else {
          await prefs.setString('phone', phone);
          _userPhone = phone;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
