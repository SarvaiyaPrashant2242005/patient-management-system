import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:patient_management_system/app/data/providers/auth_provider.dart';
import 'package:patient_management_system/app/data/providers/clinic_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final clinicsProvider =
          Provider.of<ClinicProvider>(context, listen: false);

      final email = auth.userEmail;
      if (email == null) {
        setState(() {
          _loading = false;
          _patients = [];
          _error = 'User not logged in';
        });
        return;
      }

      // Ensure clinics are loaded
      if (clinicsProvider.isInitialLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // If clinics list is empty, try loading from prefs directly
      List<Map<String, String>> clinics = clinicsProvider.clinics;
      if (clinics.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'clinics_$email';
        final clinicsJson = prefs.getString(key);
        if (clinicsJson != null) {
          final decoded = json.decode(clinicsJson) as List;
          clinics = decoded.map((e) => Map<String, String>.from(e)).toList();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> aggregated = [];

      for (final clinic in clinics) {
        final clinicName = clinic['name'];
        if (clinicName == null || clinicName.isEmpty) continue;

        final patientsKey = 'patients_${email}_$clinicName';
        final patientsJson = prefs.getString(patientsKey);
        if (patientsJson == null) continue;

        final List<dynamic> decoded = json.decode(patientsJson);
        for (final item in decoded) {
          final m = Map<String, dynamic>.from(item as Map);
          m['clinicName'] = clinicName;
          aggregated.add(m);
        }
      }

      setState(() {
        _patients = aggregated;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load patients';
        _loading = false;
        _patients = [];
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_query.trim().isEmpty) return _patients;
    final q = _query.toLowerCase();
    return _patients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final clinic = (p['clinicName'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || clinic.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Patients',
        style: TextStyle(
          color: Colors.white,
        ),),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return _buildError(_error!);
            }

            if (_patients.isEmpty) {
              return _buildEmpty();
            }

            final content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, clinic, or phone',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: isWide
                        ? _buildGrid(crossAxisCount: 3)
                        : isTablet
                            ? _buildGrid(crossAxisCount: 2)
                            : _buildList(),
                  ),
                ),
              ],
            );

            return content;
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Placeholder for future add patient flow
      //   },
      //   backgroundColor: Colors.blue,
      //   label: const Text('Add Patient'),
      //   icon: const Icon(Icons.person_add_alt_1),
      // ),
    );
  }

  Widget _buildList() {
    final data = _filteredPatients;
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PatientCard(patient: data[i]),
    );
  }

  Widget _buildGrid({required int crossAxisCount}) {
    final data = _filteredPatients;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: data.length,
      itemBuilder: (context, i) => _PatientCard(patient: data[i]),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No Patients Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add patients in clinics to see them here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadPatients,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = (patient['name'] ?? 'Unknown') as String;
    final clinicName = (patient['clinicName'] ?? '—') as String;
    final phone = (patient['phone'] ?? '—') as String;
    final gender = (patient['gender'] ?? '—') as String;
    final age = (patient['age']?.toString() ?? '—');
    final lastVisit = (patient['lastVisit'] ?? '—') as String;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Placeholder for future detail page
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.person, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_hospital_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                clinicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _iconText(Icons.event, lastVisit),
                  const SizedBox(width: 12),
                  _iconText(Icons.person_outline, '$gender, $age'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _iconText(Icons.phone, phone),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}