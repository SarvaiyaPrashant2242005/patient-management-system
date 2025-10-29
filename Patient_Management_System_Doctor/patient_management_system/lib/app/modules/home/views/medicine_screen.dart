import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patient_management_system/app/data/providers/checkup_provider.dart';
import 'package:patient_management_system/app/data/providers/medicine_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_screen.dart';


class MedicineScreen extends StatefulWidget {
  final Map<String, dynamic> checkupData;

  const MedicineScreen({super.key, required this.checkupData});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _daysController = TextEditingController();
  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedMedicineType = 'Tablet';
  bool _morningChecked = false;
  bool _afternoonChecked = false;
  bool _eveningChecked = false;
  bool _nightChecked = false;
  String _mealTiming = 'Before';

  // List to store added medicines
  final List<Map<String, dynamic>> _addedMedicines = [];

  @override
  void dispose() {
    _daysController.dispose();
    _medicineNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

void _handleAddMedicine() {
  if (_formKey.currentState!.validate()) {
    if (!_morningChecked &&
        !_afternoonChecked &&
        !_eveningChecked &&
        !_nightChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final medicineData = {
      'name': _medicineNameController.text.trim(),
      'type': _selectedMedicineType,
      'days': _daysController.text.trim(),
      'morning': _morningChecked ? 1 : 0, // Convert bool to int (0 or 1)
      'afternoon': _afternoonChecked ? 1 : 0,
      'evening': _eveningChecked ? 1 : 0,
      'night': _nightChecked ? 1 : 0,
      'mealTiming': _mealTiming,
      'quantity': _selectedMedicineType == 'Syrup'
          ? _quantityController.text.trim()
          : null,
    };

    setState(() {
      _addedMedicines.add(medicineData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine added successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    // Clear form
    _medicineNameController.clear();
    _daysController.clear();
    _quantityController.clear();
    setState(() {
      _selectedMedicineType = 'Tablet';
      _morningChecked = false;
      _afternoonChecked = false;
      _eveningChecked = false;
      _nightChecked = false;
      _mealTiming = 'Before';
    });
  }
}

  void _handleRemoveMedicine(int index) {
    setState(() {
      _addedMedicines.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine removed'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleFinish() async {
    if (_addedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving prescription...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // Get doctor name
      final doctorName = await _getDoctorName();

      // First, save the prescription using CheckupProvider
      final checkupProvider = Provider.of<CheckupProvider>(
        context,
        listen: false,
      );

      // Prepare complete checkup data with medicines
     // Prepare complete checkup data with medicines
final completeCheckupData = {
  'patientId': widget.checkupData['patientId'].toString(), // Convert to String
  'patientName': widget.checkupData['patientName'],
  'patientMobile': widget.checkupData['patientMobile'],
  'patientAge': widget.checkupData['patientAge']?.toString(), // Handle null safely
  'patientGender': widget.checkupData['patientGender'],
  'dateTime': widget.checkupData['dateTime'],
  'symptoms': widget.checkupData['symptoms'],
  'disease': widget.checkupData['disease'],
  'diagnosis': widget.checkupData['disease'],
  'clinicName': widget.checkupData['clinicName'],
  'clinicCharges': widget.checkupData['clinicCharges'].toString(),
  'totalAmount': widget.checkupData['clinicCharges'].toString(),
  'medicines': _addedMedicines,
  'doctorName': doctorName,
};
     print('Debug checkupData types:');
  print('patientAge type: ${widget.checkupData['patientAge'].runtimeType}');
  print('clinicCharges type: ${widget.checkupData['clinicCharges'].runtimeType}');
  print('Complete checkup data: $completeCheckupData');
  print('Medicines data: $_addedMedicines');
      print('Saving complete checkup data: $completeCheckupData');

      // Save prescription and get the prescription ID
     // After getting the prescription ID, store it
final presId = await checkupProvider.addCheckup(
  completeCheckupData,
  patientId: widget.checkupData['patientId'].toString(),
);

if (presId == null) {
  if (!mounted) return;
  Navigator.pop(context); // Close loading dialog
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        checkupProvider.errorMessage ?? 'Failed to save prescription',
      ),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

final String validPrescriptionId = presId.toString();
print('Prescription saved with ID: $validPrescriptionId');

// Now save individual medicines using MedicineProvider
final medicineProvider = Provider.of<MedicineProvider>(
  context,
  listen: false,
);

// Use the non-nullable variable
final medicinesSaved = await medicineProvider.addMultipleMedicines(
  _addedMedicines,
  prescriptionId: validPrescriptionId,
);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (medicinesSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Prescription Screen
        final clinicCharges = widget.checkupData['clinicCharges'] ?? '500';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionScreen(
              checkupData: widget.checkupData,
              medicines: _addedMedicines,
              clinicCharges: clinicCharges,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              medicineProvider.errorMessage ?? 'Failed to save medicines',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        // Still navigate to prescription screen as prescription was saved
        final clinicCharges = widget.checkupData['clinicCharges'] ?? '500';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionScreen(
              checkupData: widget.checkupData,
              medicines: _addedMedicines,
              clinicCharges: clinicCharges,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _handleFinish: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get doctor name
  Future<String> _getDoctorName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userName') ?? 'Doctor';
    } catch (_) {
      return 'Doctor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Add Medicine',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Name',
                        widget.checkupData['patientName'] ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.local_hospital_outlined,
                        'Disease',
                        widget.checkupData['disease'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Added Medicines List
              if (_addedMedicines.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Added Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_addedMedicines.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._addedMedicines.asMap().entries.map((entry) {
                  final index = entry.key;
                  final medicine = entry.value;
                  return _buildMedicineCard(medicine, index);
                }).toList(),
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                const SizedBox(height: 20),
              ],

              // Add Medicine Section Header
              const Text(
                'Add New Medicine',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              // Medicine Name Field
              const Text(
                'Medicine Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicineNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter medicine name',
                  prefixIcon: const Icon(
                    Icons.medication_outlined,
                    color: Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Days Field
              const Text(
                'Number of Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter number of days',
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter number of days';
                  }
                  final days = int.tryParse(value);
                  if (days == null || days <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Medicine Type Dropdown
              const Text(
                'Medicine Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMedicineType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.medical_services_outlined,
                    color: Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Tablet', child: Text('Tablet')),
                  DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMedicineType = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Quantity Field (only for Syrup)
              if (_selectedMedicineType == 'Syrup') ...[
                const Text(
                  'Quantity (ml)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter quantity in ml (e.g., 5, 10)',
                    prefixIcon: const Icon(
                      Icons.water_drop_outlined,
                      color: Colors.blue,
                    ),
                    suffixText: 'ml',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (_selectedMedicineType == 'Syrup') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter quantity in ml';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Please enter a valid quantity';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Time Selection Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'When to Take',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Morning',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _morningChecked,
                              onChanged: (value) {
                                setState(() {
                                  _morningChecked = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Afternoon',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _afternoonChecked,
                              onChanged: (value) {
                                setState(() {
                                  _afternoonChecked = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Evening',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _eveningChecked,
                              onChanged: (value) {
                                setState(() {
                                  _eveningChecked = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text(
                                'Night',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _nightChecked,
                              onChanged: (value) {
                                setState(() {
                                  _nightChecked = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meal Timing Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meal Timing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text(
                                'Before Meal',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: 'Before',
                              groupValue: _mealTiming,
                              onChanged: (value) {
                                setState(() {
                                  _mealTiming = value ?? 'Before';
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text(
                                'After Meal',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: 'After',
                              groupValue: _mealTiming,
                              onChanged: (value) {
                                setState(() {
                                  _mealTiming = value ?? 'After';
                                });
                              },
                              activeColor: Colors.blue,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Add Medicine Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleAddMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Medicine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Finish Button (only show if medicines added)
              if (_addedMedicines.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finish & Save All',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle, size: 20),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine, int index) {
    // Build timing string
   List<String> timings = [];
  if (medicine['morning'] == true || medicine['morning'] == 1) timings.add('Morning');
  if (medicine['afternoon'] == true || medicine['afternoon'] == 1) timings.add('Afternoon');
  if (medicine['evening'] == true || medicine['evening'] == 1) timings.add('Evening');
  if (medicine['night'] == true || medicine['night'] == 1) timings.add('Night');
  final timingStr = timings.join(', ');

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medicine['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _handleRemoveMedicine(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    medicine['type'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity badge (only for Syrup)
                if (medicine['type'] == 'Syrup' && medicine['quantity'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.cyan.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 12,
                          color: Colors.cyan.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${medicine['quantity']} ml',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${medicine['days']} days',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timingStr,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${medicine['mealTiming']} Meal',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
