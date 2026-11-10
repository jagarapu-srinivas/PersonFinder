import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FindPersonPage extends StatefulWidget {
  const FindPersonPage({super.key});

  @override
  State<FindPersonPage> createState() => _FindPersonPageState();
}

class _FindPersonPageState extends State<FindPersonPage> {
  final searchController = TextEditingController();
  final locationController = TextEditingController();

  String selectedGender = 'Any';

  bool searching = false;

  List<Map<String, dynamic>> searchResults = [];

  Future<void> searchPerson() async {
    final name =
        searchController.text.trim().toLowerCase();

    final location =
        locationController.text.trim().toLowerCase();

    setState(() {
      searching = true;
      searchResults = [];
    });

    try {
      // Get persons collection
      final personsSnapshot =
          await FirebaseFirestore.instance
              .collection('persons')
              .get();

      // Get reports collection
      final reportsSnapshot =
          await FirebaseFirestore.instance
              .collection('reports')
              .get();

      final results =
          <Map<String, dynamic>>[];

      // Search persons
      for (final document
          in personsSnapshot.docs) {
        final data = document.data();

        final personName =
            (data['name'] ?? '')
                .toString()
                .toLowerCase();

        final personLocation =
            (data['lastSeenLocation'] ?? '')
                .toString()
                .toLowerCase();

        final personGender =
            (data['gender'] ?? '')
                .toString();

        bool nameMatches = true;
        bool locationMatches = true;
        bool genderMatches = true;

        if (name.isNotEmpty) {
          nameMatches =
              personName.contains(name);
        }

        if (location.isNotEmpty) {
          locationMatches =
              personLocation.contains(location);
        }

        if (selectedGender != 'Any') {
          genderMatches =
              personGender == selectedGender;
        }

        if (nameMatches &&
            locationMatches &&
            genderMatches) {
          results.add({
            'id': document.id,
            'type': 'Person',
            ...data,
          });
        }
      }

      // Search missing reports
      for (final document
          in reportsSnapshot.docs) {
        final data = document.data();

        final personName =
            (data['name'] ?? '')
                .toString()
                .toLowerCase();

        final personLocation =
            (data['lastSeenLocation'] ?? '')
                .toString()
                .toLowerCase();

        bool nameMatches = true;
        bool locationMatches = true;

        if (name.isNotEmpty) {
          nameMatches =
              personName.contains(name);
        }

        if (location.isNotEmpty) {
          locationMatches =
              personLocation.contains(location);
        }

        // Reports currently don't contain gender.
        // Therefore gender filter is ignored
        // for reports.

        if (nameMatches &&
            locationMatches) {
          results.add({
            'id': document.id,
            'type': 'Missing Report',
            ...data,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        searchResults = results;
        searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        searching = false;
      });

      showMessage(
        'Unable to search database.',
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Person'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Person',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Search for a person or missing person report.',
            ),

            const SizedBox(height: 25),

            // Name
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Person Name',
                hintText: 'Enter name',
                prefixIcon:
                    const Icon(Icons.person_search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Location
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter city or area',
                prefixIcon:
                    const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Gender
            DropdownButtonFormField<String>(
              initialValue: selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Any',
                  child: Text('Any'),
                ),
                DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender =
                      value ?? 'Any';
                });
              },
            ),

            const SizedBox(height: 25),

            // Search button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    searching ? null : searchPerson,
                icon: searching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  searching
                      ? 'Searching...'
                      : 'Search Person',
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Search Results',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (!searching &&
                searchResults.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'No results found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            ...searchResults.map(
              (person) {
                return _personCard(person);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _personCard(
    Map<String, dynamic> person,
  ) {
    final name =
        person['name'] ?? 'Unknown';

    final age =
        person['age'] ?? 'Unknown';

    final gender =
        person['gender'] ?? 'Not provided';

    final location =
        person['lastSeenLocation'] ??
            'Unknown';

    final phone =
        person['phone'] ??
            'Not available';

    final description =
        person['description'] ??
            'No description';

    final status =
        person['status'] ??
            'Unknown';

    final type =
        person['type'] ??
            'Person';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Type
            Row(
              children: [
                Icon(
                  type == 'Missing Report'
                      ? Icons.report_problem
                      : Icons.person,
                ),

                const SizedBox(width: 8),

                Text(
                  type.toString(),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 35,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Age: $age',
                      ),

                      Text(
                        'Gender: $gender',
                      ),
                    ],
                  ),
                ),

                Text(
                  status.toString(),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    location.toString(),
                  ),
                ),
              ],
            ),

            if (phone
                .toString()
                .isNotEmpty &&
                phone.toString() !=
                    'Not available') ...[
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    phone.toString(),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Text(
              description.toString(),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}