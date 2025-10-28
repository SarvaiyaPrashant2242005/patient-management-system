import 'package:flutter/material.dart';
import 'package:patient_management_system/app/data/providers/auth_provider.dart';
import 'package:patient_management_system/app/data/providers/patient_provider.dart';
import 'package:patient_management_system/app/modules/home/views/patient_form.dart';
import 'package:patient_management_system/app/modules/home/views/patient_screen.dart';
import 'package:patient_management_system/app/shared/widgets/loader.dart';
import 'package:provider/provider.dart';

class ClinicPage extends StatefulWidget {
  final Map<String, String> clinicData;

  const ClinicPage({super.key, required this.clinicData});

  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  @override
  void initState() {
    super.initState();
    // Load patients when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );

      if (authProvider.userEmail != null && widget.clinicData['name'] != null) {
        patientProvider.loadPatients(
          widget.clinicData['name']!,
          authProvider.userEmail!,
        );
      }
    });
  }

  // Open bottom sheet to add/edit patient
  Future<void> _openPatientForm({
    Map<String, dynamic>? patient,
    int? index,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: PatientFormPage(patient: patient, patientIndex: index),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Patients Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a patient',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _deletePatient(int index, String patientName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Delete Patient",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        content: Text(
          "Are you sure you want to delete $patientName?",
          style: const TextStyle(color: Colors.black87),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final patientProvider = Provider.of<PatientProvider>(
                context,
                listen: false,
              );
              final success = await patientProvider.deletePatient(index);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Patient deleted successfully"
                          : "Failed to delete patient",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinicData;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinic['name'] ?? 'Clinic Details',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              clinic['landline'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),

      ),
      body: Consumer<PatientProvider>(
        builder: (context, patientProvider, _) {
          // Show loader while initial loading
          if (patientProvider.isInitialLoading) {
            return const Center(child: AppLoader(size: 120));
          }

          // Show empty state if no patients
          if (patientProvider.patients.isEmpty) {
            return _buildEmptyState();
          }

          // Show patients list
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Patient List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: patientProvider.patients.length,
                    itemBuilder: (context, index) {
                      final patient = patientProvider.patients[index];
                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(patient['name'] ?? 'Unknown'),
                          subtitle: Text("${patient['mobile'] ?? 'N/A'}"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientScreenPage(
                                  patientData: patient,
                                  clinicName: widget.clinicData['name'] ?? '',
                                  clinicData: widget.clinicData,
                                ),
                              ),
                            );
                          },
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _openPatientForm(
                                  patient: patient,
                                  index: index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePatient(
                                  index,
                                  patient['name'] ?? 'Unknown',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _openPatientForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
