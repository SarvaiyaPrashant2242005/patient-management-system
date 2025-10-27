import 'package:flutter/material.dart';

class PatientScreenPage extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const PatientScreenPage({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final patient = patientData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(patient['name'] ?? 'Patient Details', style: TextStyle(
          color: Colors.white
        ),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
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
                ),
                _buildActionButton(
                  context,
                  "Payment",
                  Icons.payment_outlined,
                  Colors.green,
                ),
                _buildActionButton(
                  context,
                  "Lab Test",
                  Icons.science_outlined,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$label clicked")));
      },
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
}
