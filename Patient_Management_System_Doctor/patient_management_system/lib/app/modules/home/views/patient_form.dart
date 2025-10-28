import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/patient_provider.dart';
import '../../../shared/widgets/loader.dart';

class PatientFormPage extends StatefulWidget {
  final Map<String, dynamic>? patient; // For editing existing patient
  final int? patientIndex; // Index for updating

  const PatientFormPage({super.key, this.patient, this.patientIndex});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _gender;
  bool _isSubmitting = false;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();

    // If editing existing patient
    if (widget.patient != null) {
      _nameController.text = widget.patient!['name'] ?? '';
      _mobileController.text = widget.patient!['mobile'] ?? '';
      final dobStr = widget.patient!['dob'] ?? '';
      if (dobStr.isNotEmpty) {
        try {
          _selectedDob = DateFormat('dd-MM-yyyy').parse(dobStr);
          _dobController.text = dobStr;
        } catch (_) {
          // Try parsing other formats if needed
        }
      }
      _ageController.text = widget.patient!['age'] ?? '';
      _gender = widget.patient!['gender'];
      _heightController.text = widget.patient!['height'] ?? '';
      _weightController.text = widget.patient!['weight'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Calculate age from DOB
  void _calculateAgeFromDob() {
    if (_selectedDob == null) return;
    final today = DateTime.now();
    int age = today.year - _selectedDob!.year;
    if (today.month < _selectedDob!.month ||
        (today.month == _selectedDob!.month && today.day < _selectedDob!.day)) {
      age--;
    }
    _ageController.text = age.toString();
  }

  // Show date picker for DOB
  Future<void> _selectDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
        _calculateAgeFromDob();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final patientData = {
      'name': _nameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'dob': _dobController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': _gender ?? '',
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
    };

    setState(() => _isSubmitting = true);

    bool success;
    if (widget.patient != null && widget.patientIndex != null) {
      // Update existing patient
      success = await patientProvider.updatePatient(widget.patientIndex!, patientData);
    } else {
      // Add new patient
      success = await patientProvider.addPatient(patientData);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.patient != null
                ? 'Patient updated successfully'
                : 'Patient added successfully',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save patient. Please try again.',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                Text(
                  widget.patient != null
                      ? 'Update Patient Details'
                      : 'Add New Patient',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.patient != null
                      ? 'Edit the patient information below'
                      : 'Fill in the patient information below',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Name
                _buildLabel("Full Name", isRequired: true),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  decoration: _buildInputDecoration(
                    hintText: 'Enter patient name',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
                      return 'Only alphabets and spaces allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Mobile
                _buildLabel("Mobile Number", isRequired: true),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _buildInputDecoration(
                    hintText: 'Enter mobile number',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Mobile number is required';
                    if (v.length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // DOB and Age in one row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Date of Birth", isRequired: true),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: _selectDob,
                            decoration: _buildInputDecoration(
                              hintText: 'DD-MM-YYYY',
                              prefixIcon: Icons.cake_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'DOB is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Age", isRequired: true),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _ageController,
                            readOnly: _selectedDob != null,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _buildInputDecoration(
                              hintText: 'Age',
                              prefixIcon: Icons.calendar_today_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Age is required';
                              final age = int.tryParse(v);
                              if (age == null || age < 0 || age > 120) {
                                return 'Enter a valid age';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Gender
                _buildLabel("Gender", isRequired: true),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _buildInputDecoration(
                    hintText: 'Select gender',
                    prefixIcon: Icons.wc_outlined,
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _gender = val),
                  validator: (v) => v == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 10),

                // Height and Weight in one row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Height (cm)", isRequired: false),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'Height',
                              prefixIcon: Icons.height_outlined,
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final height = int.tryParse(v);
                                if (height == null || height > 1000) {
                                  return 'Max 1000 cm';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Weight (kg)", isRequired: false),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _buildInputDecoration(
                              hintText: 'Weight',
                              prefixIcon: Icons.monitor_weight_outlined,
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final weight = int.tryParse(v);
                                if (weight == null || weight > 1000) {
                                  return 'Max 1000 kg';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Submit button
                SizedBox(
                  height: 50,
                  child: _isSubmitting
                      ? const AppLoader(size: 40)
                      : ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.patient != null
                          ? 'Update Patient'
                          : 'Add Patient',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // 🔹 Label Helper
  Widget _buildLabel(String text, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  // 🔹 InputDecoration Helper
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
