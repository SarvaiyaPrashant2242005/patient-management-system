import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'checkup_screen.dart';
import 'payment_screen.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_system/app/data/providers/payment_provider.dart';

class PatientScreenPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final String clinicName;
  final Map<String, String> clinicData;

  const PatientScreenPage({
    super.key,
    required this.patientData,
    required this.clinicName,
    required this.clinicData,
  });

  @override
  Widget build(BuildContext context) {
    final patient = patientData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(patient['name'] ?? 'Patient Details', style: TextStyle(
          color: Colors.white
        ),),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Patient Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow("👤 Name", patient['name'] ?? 'N/A'),
                    _buildDetailRow("📞 Mobile", patient['mobile'] ?? 'N/A'),
                    _buildDetailRow("🎂 Age", patient['age'] ?? 'N/A'),
                    _buildDetailRow("⚧ Gender", patient['gender'] ?? 'N/A'),
                    _buildDetailRow("📍 Address", patient['address'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  "Checkup",
                  Icons.medical_services_outlined,
                  Colors.blue,
                  onTap: () {
                    if (!_ensureValidNameOrNotify(context)) return;
                    final charges = clinicData['charges'] ?? '500';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckupScreen(
                          patientData: patientData,
                          clinicName: clinicName,
                          clinicCharges: charges,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Payment",
                  Icons.payment_outlined,
                  Colors.green,
                  onTap: () async {
                    if (!_ensureValidNameOrNotify(context)) return;
                    final mobile = patient['mobile'] ?? '';
                    double currentCharges = 0;
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final raw = prefs.getString('prescriptions_$mobile');
                      if (raw != null) {
                        final List<dynamic> decoded = json.decode(raw);
                        if (decoded.isNotEmpty) {
                          final latest = Map<String, dynamic>.from(decoded.first);
                          final amt = double.tryParse((latest['totalAmount'] ?? '0').toString());
                          if (amt != null) currentCharges = amt;
                        }
                      }
                    } catch (_) {}

                    String doctorName = 'Doctor';
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      doctorName = prefs.getString('userName') ?? doctorName;
                    } catch (_) {}

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => PaymentProvider(),
                          child: PatientPaymentPage(
                            patient: patientData,
                            doctorName: doctorName,
                            currentCharges: currentCharges,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  "Lab Test",
                  Icons.science_outlined,
                  Colors.orange,
                  onTap: () {
                    if (!_ensureValidNameOrNotify(context)) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lab Test clicked")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Prescription History Inline
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: const [
                  Icon(Icons.history, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Prescription History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadPrescriptions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Failed to load prescriptions', style: TextStyle(color: Colors.red[700])),
                  );
                }
                final prescriptions = snapshot.data ?? [];
                if (prescriptions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('No prescription history found', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    return _buildPrescriptionCard(prescriptions[index], context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidName(String name) {
    final reg = RegExp(r'^[A-Za-z .]+ ?');
    final basic = RegExp(r'^[A-Za-z .]+$');
    return name.isNotEmpty && basic.hasMatch(name) && RegExp(r'[A-Za-z]').hasMatch(name);
  }

  bool _ensureValidNameOrNotify(BuildContext context) {
    final name = (patientData['name'] ?? '').toString();
    if (_isValidName(name)) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid patient name. Only letters, spaces, and dots allowed.')),
    );
    return false;
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadPrescriptions() async {
    // Load prescription history from storage
    final prefs = await SharedPreferences.getInstance();
    final patientMobile = patientData['mobile'] ?? '';
    final key = 'prescriptions_$patientMobile';

    List<Map<String, dynamic>> prescriptions = [];
    final existingData = prefs.getString(key);

    if (existingData != null) {
      try {
        final List<dynamic> decoded = json.decode(existingData);
        prescriptions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        // ignore parse errors, return empty
      }
    }

    return prescriptions;
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription, BuildContext context) {
    final date = prescription['dateTime'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(prescription['dateTime']))
        : 'N/A';
    final medicines = prescription['medicines'] as List<dynamic>? ?? [];
    
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medical_services, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription['disease'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                  _buildInfoChip(Icons.medication, '${medicines.length} Medicines', Colors.blue),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.currency_rupee, '₹${prescription['totalAmount']}', Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Clinic: ${prescription['clinicName'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _unused_showPrescriptionDetails(Map<String, dynamic> prescription, BuildContext context) {
    final medicines = prescription['medicines'] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Prescription Details',
            style: TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection('Disease', prescription['disease'] ?? 'N/A'),
                _buildDetailSection('Symptoms', prescription['symptoms'] ?? 'N/A'),
                _buildDetailSection('Clinic', prescription['clinicName'] ?? 'N/A'),
                const SizedBox(height: 12),
                const Text(
                  'Medicines:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...medicines.map((med) {
                  final timings = <String>[];
                  if (med['morning'] == true) timings.add('Morning');
                  if (med['afternoon'] == true) timings.add('Afternoon');
                  if (med['evening'] == true) timings.add('Evening');
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Type: ${med['type']}, Days: ${med['days']}'),
                        Text('Timing: ${timings.join(', ')}'),
                        Text('${med['mealTiming']} Meal'),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '₹${prescription['totalAmount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
