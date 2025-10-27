import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> checkupData;
  final List<Map<String, dynamic>> medicines;
  final String clinicCharges;

  const PrescriptionScreen({
    super.key,
    required this.checkupData,
    required this.medicines,
    required this.clinicCharges,
  });

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  int _getMaxDays() {
    if (widget.medicines.isEmpty) return 0;
    int maxDays = 0;
    for (var medicine in widget.medicines) {
      final days = int.tryParse(medicine['days'].toString()) ?? 0;
      if (days > maxDays) maxDays = days;
    }
    return maxDays;
  }

  double _calculateTotalAmount() {
    final maxDays = _getMaxDays();
    final charges = double.tryParse(widget.clinicCharges) ?? 0;
    return maxDays * charges;
  }

  void _handlePayment() {
    // Store the page context BEFORE opening the dialog
    final pageContext = context;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Payment',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                '₹${_calculateTotalAmount().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirm payment?',
                style: TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Save prescription data first
                  await _savePrescription();
                  print('Prescription saved successfully');

                  // Close the payment dialog using dialog context
                  Navigator.pop(dialogContext);

                  // Show success message using page context
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                      content: Text('Payment processed & Prescription saved!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Allow SnackBar to be seen briefly before navigating
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Navigate back using page context
                  print('Starting navigation from prescription page...');

                  // Pop 4 times: prescription -> medicine -> checkup -> patient -> back to clinic
                  Navigator.of(pageContext).pop(); // Pop prescription
                  Navigator.of(pageContext).pop(); // Pop medicine
                  Navigator.of(pageContext).pop(); // Pop checkup
                  Navigator.of(pageContext).pop(); // Pop patient

                  print('Navigation completed - should be at ClinicPage now');

                } catch (e) {
                  print('Error in payment: $e');
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  String _generatePrescriptionText() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('         PRESCRIPTION');
    buffer.writeln('═══════════════════════════════════\n');

    // Patient Info
    buffer.writeln('PATIENT INFORMATION:');
    buffer.writeln('Name: ${widget.checkupData['patientName']}');
    buffer.writeln('Mobile: ${widget.checkupData['patientMobile']}');
    buffer.writeln(
      'Age: ${widget.checkupData['patientAge']} | Gender: ${widget.checkupData['patientGender']}',
    );
    buffer.writeln('');

    // Checkup Details
    buffer.writeln('CHECKUP DETAILS:');
    buffer.writeln('Clinic: ${widget.checkupData['clinicName']}');
    if (widget.checkupData['dateTime'] != null) {
      buffer.writeln(
        'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(widget.checkupData['dateTime']))}',
      );
    }
    buffer.writeln('Symptoms: ${widget.checkupData['symptoms']}');
    buffer.writeln('Disease: ${widget.checkupData['disease']}');
    buffer.writeln('');

    // Medicines
    buffer.writeln('PRESCRIBED MEDICINES (${widget.medicines.length}):');
    buffer.writeln('───────────────────────────────────');
    for (int i = 0; i < widget.medicines.length; i++) {
      final medicine = widget.medicines[i];
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

    // Bill Summary
    final maxDays = _getMaxDays();
    final totalAmount = _calculateTotalAmount();
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('BILL SUMMARY:');
    buffer.writeln('Consultation Charges: ₹${widget.clinicCharges}');
    buffer.writeln('Treatment Days: $maxDays days');
    buffer.writeln('Total Amount: ₹${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  void _handleShare() {
    final prescriptionText = _generatePrescriptionText();
    Clipboard.setData(ClipboardData(text: prescriptionText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _savePrescription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientMobile = widget.checkupData['patientMobile'] ?? '';
      final key = 'prescriptions_$patientMobile';

      final existingData = prefs.getString(key);
      List<Map<String, dynamic>> prescriptions = [];

      if (existingData != null) {
        final List<dynamic> decoded = json.decode(existingData);
        prescriptions = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      final prescription = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'patientName': widget.checkupData['patientName'],
        'patientMobile': widget.checkupData['patientMobile'],
        'patientAge': widget.checkupData['patientAge'],
        'patientGender': widget.checkupData['patientGender'],
        'clinicName': widget.checkupData['clinicName'],
        'dateTime': widget.checkupData['dateTime'],
        'symptoms': widget.checkupData['symptoms'],
        'disease': widget.checkupData['disease'],
        'medicines': widget.medicines,
        'clinicCharges': widget.clinicCharges,
        'totalAmount': _calculateTotalAmount().toStringAsFixed(2),
        'treatmentDays': _getMaxDays(),
      };

      prescriptions.insert(0, prescription);

      await prefs.setString(key, json.encode(prescriptions));

      print('Prescription saved successfully for patient: $patientMobile');
    } catch (e) {
      print('Error saving prescription: $e');
    }
  }

  void _handlePrint() {
    final prescriptionText = _generatePrescriptionText();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Prescription Preview',
            style: TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prescriptionText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: prescriptionText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prescription copied! Ready to print.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Copy to Print'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final maxDays = _getMaxDays();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Prescription',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _handleShare,
            tooltip: 'Share Prescription',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _handlePrint,
            tooltip: 'Print Prescription',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Information Card
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
                      Icons.phone_outlined,
                      'Mobile',
                      widget.checkupData['patientMobile'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.cake_outlined,
                            'Age',
                            widget.checkupData['patientAge'] ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            Icons.wc_outlined,
                            'Gender',
                            widget.checkupData['patientGender'] ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checkup Details Card
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
                      'Checkup Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      Icons.local_hospital_outlined,
                      'Clinic',
                      widget.checkupData['clinicName'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Date',
                      widget.checkupData['dateTime'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(
                              DateTime.parse(widget.checkupData['dateTime']),
                            )
                          : 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.medical_information_outlined,
                      'Symptoms',
                      widget.checkupData['symptoms'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.healing_outlined,
                      'Disease',
                      widget.checkupData['disease'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prescribed Medicines Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prescribed Medicines',
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
                    '${widget.medicines.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Medicines List
            ...widget.medicines.asMap().entries.map((entry) {
              final index = entry.key;
              final medicine = entry.value;
              return _buildMedicineCard(medicine, index + 1);
            }).toList(),

            const SizedBox(height: 16),

            // Bill Summary Card
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade200, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Consultation Charges:',
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                        Text(
                          '₹${widget.clinicCharges}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Treatment Days:',
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                        Text(
                          '$maxDays days',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculation: $maxDays days × ₹${widget.clinicCharges}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Proceed to Payment - ₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildMedicineCard(Map<String, dynamic> medicine, int number) {
    // Build timing string
    List<String> timings = [];
    if (medicine['morning'] == true) timings.add('Morning');
    if (medicine['afternoon'] == true) timings.add('Afternoon');
    if (medicine['evening'] == true) timings.add('Evening');
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
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 10),
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
