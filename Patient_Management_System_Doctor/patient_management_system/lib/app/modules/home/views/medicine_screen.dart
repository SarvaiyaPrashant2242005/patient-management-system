import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prescription_screen.dart';

class MedicineScreen extends StatefulWidget {
  final Map<String, dynamic> checkupData;

  const MedicineScreen({
    super.key,
    required this.checkupData,
  });

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
      if (!_morningChecked && !_afternoonChecked && !_eveningChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one time (Morning/Afternoon/Evening)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final medicineData = {
        'name': _medicineNameController.text.trim(),
        'type': _selectedMedicineType,
        'days': _daysController.text.trim(),
        'morning': _morningChecked,
        'afternoon': _afternoonChecked,
        'evening': _eveningChecked,
        'mealTiming': _mealTiming,
        'quantity': _selectedMedicineType == 'Syrup' ? _quantityController.text.trim() : null,
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

  void _handleFinish() {
    if (_addedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get clinic charges from checkup data, default to '500' if not available
    final clinicCharges = widget.checkupData['clinicCharges'] ?? '500';
    
    print('Medicine - Clinic Charges from checkupData: $clinicCharges');
    print('Medicine - Full checkupData: ${widget.checkupData}');

    // Navigate to Prescription Screen
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
                  DropdownMenuItem(
                    value: 'Tablet',
                    child: Text('Tablet'),
                  ),
                  DropdownMenuItem(
                    value: 'Syrup',
                    child: Text('Syrup'),
                  ),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                      CheckboxListTile(
                        title: const Text('Morning'),
                        value: _morningChecked,
                        onChanged: (value) {
                          setState(() {
                            _morningChecked = value ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Afternoon'),
                        value: _afternoonChecked,
                        onChanged: (value) {
                          setState(() {
                            _afternoonChecked = value ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Evening'),
                        value: _eveningChecked,
                        onChanged: (value) {
                          setState(() {
                            _eveningChecked = value ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
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
                      RadioListTile<String>(
                        title: const Text('Before Meal'),
                        value: 'Before',
                        groupValue: _mealTiming,
                        onChanged: (value) {
                          setState(() {
                            _mealTiming = value ?? 'Before';
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: const Text('After Meal'),
                        value: 'After',
                        groupValue: _mealTiming,
                        onChanged: (value) {
                          setState(() {
                            _mealTiming = value ?? 'After';
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Finish & Save All',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 20),
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
    if (medicine['morning']) timings.add('Morning');
    if (medicine['afternoon']) timings.add('Afternoon');
    if (medicine['evening']) timings.add('Evening');
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.cyan.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop, size: 12, color: Colors.cyan.shade700),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.orange.shade700),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}