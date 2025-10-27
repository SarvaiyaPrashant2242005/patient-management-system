import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patient_management_system/app/data/providers/auth_provider.dart';
import 'package:patient_management_system/app/data/providers/clinic_provider.dart';
import 'package:patient_management_system/app/modules/auth/views/LoginPage.dart';
import 'package:patient_management_system/app/modules/home/views/clinic_screen.dart';
import 'package:patient_management_system/app/shared/widgets/loader.dart';
import 'package:provider/provider.dart';

import 'clinic_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);
      
      if (authProvider.userEmail != null) {
        clinicProvider.loadClinics(authProvider.userEmail!);
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logOutUser();
                
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade300,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _deleteClinic(int index, String clinicName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Clinic',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$clinicName"?',
            style: const TextStyle(color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);
                final success = await clinicProvider.deleteClinic(index);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Clinic deleted successfully'
                          : 'Failed to delete clinic'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddClinicSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const ClinicFormPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userName = authProvider.userName ?? 'Doctor';
        final userEmail = authProvider.userEmail ?? 'email@example.com';
        
        return Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            backgroundColor: Colors.blue,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('My Clinics'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Appointments'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {},
            ),
            const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
          body: Consumer<ClinicProvider>(
            builder: (context, clinicProvider, _) {
              // Show loader while initial loading
              if (clinicProvider.isInitialLoading) {
                return const Center(
                  child: AppLoader(size: 120),
                );
              }

              // Show empty state if no clinics
              if (clinicProvider.clinics.isEmpty) {
                return _buildEmptyState();
              }

              // Show clinics list
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: clinicProvider.clinics.length,
                itemBuilder: (context, index) {
                  return _buildClinicCard(index, clinicProvider.clinics[index]);
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddClinicSheet,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Clinics Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a clinic',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(int index, Map<String, String> clinic) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicPage(clinicData: clinic),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Name
              Text(
                clinic['name']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 5),

              // Landline Number
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clinic['landline']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clinic['address']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.white,
                        builder: (_) => ClinicFormPage(
                          clinic: clinic,
                          clinicIndex: index,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 5),
                  TextButton.icon(
                    onPressed: () => _deleteClinic(index, clinic['name']!),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddClinicSheet extends StatefulWidget {
  final Future<void> Function() onAdded;
  final Function(Map<String, String>) onSubmit;

  const AddClinicSheet({
    super.key,
    required this.onAdded,
    required this.onSubmit,
  });

  @override
  State<AddClinicSheet> createState() => _AddClinicSheetState();
}

class _AddClinicSheetState extends State<AddClinicSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _landlineController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _landlineController.dispose();
    _doctorNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _submitting = false);

    // Call onSubmit to add clinic data
    widget.onSubmit({
      'name': _clinicNameController.text.trim(),
      'landline': _landlineController.text.trim(),
      'doctorName': _doctorNameController.text.trim(),
      'address': _addressController.text.trim(),
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Clinic added successfully',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 20, left: 50, right: 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 6,
        duration: Duration(seconds: 2),
      ),
    );

    // Call onAdded callback
    await widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Clinic',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Clinic Name
          _buildLabel('Clinic Name', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _clinicNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter clinic name',
              prefixIcon: Icon(
                Icons.local_hospital_outlined,
                color: Colors.blue,
              ),
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Clinic name is required'
                : null,
          ),
          const SizedBox(height: 16),

          // Landline Number
          _buildLabel('Landline Number', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _landlineController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\-\s\(\)]')),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g., 0283-2234567',
              prefixIcon: Icon(Icons.phone_outlined, color: Colors.blue),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Landline number is required';
              }
              final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (cleaned.length < 10) {
                return 'Please enter a valid landline number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Doctor Name
          _buildLabel('Doctor Name', isRequired: false),
          const SizedBox(height: 8),
          TextFormField(
            controller: _doctorNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter doctor name (optional)',
              prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          _buildLabel('Address', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter complete address',
              prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blue),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _submitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Add Clinic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 15)),
      ],
    );
  }
}
