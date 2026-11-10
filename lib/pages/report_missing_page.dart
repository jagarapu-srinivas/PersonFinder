import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportMissingPage extends StatefulWidget {
  const ReportMissingPage({super.key});

  @override
  State<ReportMissingPage> createState() => _ReportMissingPageState();
}

class _ReportMissingPageState extends State<ReportMissingPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String gender = 'Male';
  String status = 'Missing';
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitReport() async {
    final name = nameController.text.trim();
    final ageText = ageController.text.trim();
    final location = locationController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || ageText.isEmpty || location.isEmpty) {
      showMessage('Please fill in Name, Age and Last Seen Location.');
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age < 0 || age > 120) {
      showMessage('Please enter a valid age.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showMessage('Please login before reporting a missing person.');
      return;
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'name': name,
        'age': age,
        'gender': gender,
        'phone': phoneController.text.trim(),
        'lastSeenLocation': location,
        'description': description,
        'status': status,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      clearForm();
      showMessage('Report submitted successfully.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showMessage('Unable to submit report: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to submit report.');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void clearForm() {
    nameController.clear();
    ageController.clear();
    phoneController.clear();
    locationController.clear();
    descriptionController.clear();

    setState(() {
      gender = 'Male';
      status = 'Missing';
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Missing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Missing Person Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the details of the missing person.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter full name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age *',
                hintText: 'Enter age',
                prefixIcon: const Icon(Icons.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => gender = value);
                }
              },
            ),
            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: locationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Last Seen Location *',
                hintText: 'City / Area',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: InputDecoration(
                labelText: 'Report Status',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Missing', child: Text('Missing')),
                DropdownMenuItem(value: 'Found', child: Text('Found')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => status = value);
                }
              },
            ),
            const SizedBox(height: 15),

            TextField(
              controller: descriptionController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Add any useful details',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : submitReport,
                icon: const Icon(Icons.send),
                label: Text(saving ? 'Submitting...' : 'Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
