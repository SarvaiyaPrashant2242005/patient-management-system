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
  bool _manualDob = false; // Manual DOB toggle

  @override
  void initState() {
    super.initState();

    // If editing existing patient
    if (widget.patient != null) {
      _nameController.text = widget.patient!['name'] ?? '';
      _mobileController.text = widget.patient!['mobile'] ?? '';
      _dobController.text = widget.patient!['dob'] ?? '';
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

  // 🔹 When age is entered → auto-generate DOB as Jan 1 of (currentYear - age)
  void _updateDobFromAge(String ageText) {
    if (_manualDob) return; // skip auto if manual DOB enabled
    if (ageText.isEmpty) {
      _dobController.clear();
      return;
    }
    final age = int.tryParse(ageText);
    if (age == null) return;

    final currentYear = DateTime.now().year;
    final birthYear = currentYear - age;
    final dob = DateTime(birthYear, 1, 1);
    _dobController.text = DateFormat('yyyy-MM-dd').format(dob);
  }

  // 🔹 Update age if DOB manually changed
  void _updateAgeFromDob(String dobText) {
    if (dobText.isEmpty) return;
    try {
      final dob = DateFormat('yyyy-MM-dd').parse(dobText);
      final today = DateTime.now();
      final age = today.year - dob.year;
      _ageController.text = age.toString();
    } catch (_) {}
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
                  decoration: _buildInputDecoration(
                    hintText: 'Enter patient name',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
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

                // Age
                _buildLabel("Age", isRequired: true),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _buildInputDecoration(
                    hintText: 'Enter age in years',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                  onChanged: _updateDobFromAge,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Age is required';
                    final age = int.tryParse(v);
                    if (age == null || age < 0 || age > 120) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // DOB (Auto / Manual)
                _buildLabel("Date of Birth", isRequired: false),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _dobController,
                  readOnly: !_manualDob,
                  onTap: _manualDob
                      ? () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _dobController.text.isNotEmpty
                          ? DateFormat('yyyy-MM-dd')
                          .parse(_dobController.text)
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _dobController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                      _updateAgeFromDob(_dobController.text);
                    }
                  }
                      : null,
                  onChanged: _manualDob
                      ? (val) => _updateAgeFromDob(val)
                      : null,
                  decoration: _buildInputDecoration(
                    hintText: _manualDob
                        ? 'Enter or pick DOB manually'
                        : 'Auto-filled based on age (1st Jan)',
                    prefixIcon: Icons.cake_outlined,
                  ),
                ),
                const SizedBox(height: 10),

                // Toggle manual DOB
                TextButton.icon(
                  onPressed: () => setState(() => _manualDob = !_manualDob),
                  icon: Icon(
                    _manualDob ? Icons.toggle_on : Icons.toggle_off,
                    color: Colors.blue,
                  ),
                  label: Text(
                      _manualDob ? 'Manual DOB Enabled' : 'Manual DOB Disabled'),
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

                // Height
                _buildLabel("Height (cm)", isRequired: false),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter height in centimeters',
                    prefixIcon: Icons.height_outlined,
                  ),
                ),
                const SizedBox(height: 10),

                // Weight
                _buildLabel("Weight (kg)", isRequired: false),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter weight in kilograms',
                    prefixIcon: Icons.monitor_weight_outlined,
                  ),
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
