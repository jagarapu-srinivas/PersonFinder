import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 1. DOMAIN MODELS & ENUMS
// ============================================================================

enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  final String label;
  const Gender(this.label);
}

enum PersonStatus {
  missing('Missing'),
  found('Found');

  final String label;
  const PersonStatus(this.label);
}

@immutable
class Person {
  final String? id;
  final String name;
  final int age;
  final Gender gender;
  final String phone;
  final String lastSeenLocation;
  final String description;
  final PersonStatus status;
  final String createdBy;
  final DateTime? createdAt;

  const Person({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.lastSeenLocation,
    required this.description,
    required this.status,
    required this.createdBy,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'gender': gender.name,
      'phone': phone,
      'lastSeenLocation': lastSeenLocation,
      'description': description,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// ============================================================================
// 2. DATA REPOSITORY INTERFACE & IMPLEMENTATION
// ============================================================================

abstract interface class PersonRepository {
  Future<String> savePersonReport(Person person);
  String? get currentUserId;
}

class FirestorePersonRepository implements PersonRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestorePersonRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String> savePersonReport(Person person) async {
    final batch = _firestore.batch();
    final personDoc = _firestore.collection('persons').doc();
    final reportDoc = _firestore.collection('reports').doc();

    final payload = person.toFirestore();

    batch.set(personDoc, payload);
    batch.set(reportDoc, {
      ...payload,
      'personId': personDoc.id,
      'source': 'add_person_form',
    });

    await batch.commit();
    return personDoc.id;
  }
}

// ============================================================================
// 3. PRESENTATION SCREEN (VIEW & CONTROLLER)
// ============================================================================

class AddPersonPage extends StatefulWidget {
  final PersonRepository repository;

  AddPersonPage({super.key, PersonRepository? repository})
      : repository = repository ?? FirestorePersonRepository();

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  Gender _selectedGender = Gender.male;
  PersonStatus _selectedStatus = PersonStatus.missing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Dismiss soft keyboard
    FocusScope.of(context).unfocus();

    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) {
      _showFeedback(
        'Please review the highlighted fields before submitting.',
        isError: true,
      );
      return;
    }

    // 2. Validate User Authentication
    final userId = widget.repository.currentUserId;
    if (userId == null) {
      _showFeedback(
        'Authentication required. Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final person = Person(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        phone: _phoneController.text.trim(),
        lastSeenLocation: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        createdBy: userId,
      );

      final documentId = await widget.repository.savePersonReport(person);

      if (!mounted) return;
      _showFeedback('Person record saved successfully! (ID: $documentId)');
      _resetForm();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showFeedback(e.message ?? 'A database error occurred.', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Unexpected error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _locationController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedGender = Gender.male;
      _selectedStatus = PersonStatus.missing;
    });
  }

  void _showFeedback(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: isError
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor:
              isError ? theme.colorScheme.error : theme.colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Person Report',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _resetForm,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                'Person Identification',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete the form below to publish an official report.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildAvatarPicker(theme),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildAgeField(),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 28),
              _buildSubmitButton(),
              const SizedBox(height: 12),
              _buildResetButton(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '* Denotes mandatory fields',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(ThemeData theme) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_rounded,
              size: 58,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton.filledTonal(
            iconSize: 20,
            onPressed: _isLoading
                ? null
                : () => _showFeedback('Photo attachments will be supported soon.'),
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Add Photo',
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      enabled: !_isLoading,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Full Name *',
        hintText: 'e.g., Jane Doe',
        prefixIcon: Icon(Icons.person_outline_rounded),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Full Name is required.';
        if (val.trim().length < 2) return 'Name must be at least 2 characters.';
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      enabled: !_isLoading,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: const InputDecoration(
        labelText: 'Age *',
        hintText: 'e.g., 28',
        prefixIcon: Icon(Icons.cake_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Age is required.';
        final parsedAge = int.tryParse(val.trim());
        if (parsedAge == null || parsedAge < 0 || parsedAge > 125) {
          return 'Enter an age between 0 and 125.';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<Gender>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.transgender_rounded),
        border: OutlineInputBorder(),
      ),
      items: Gender.values.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender.label),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (val) {
              if (val != null) setState(() => _selectedGender = val);
            },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      enabled: !_isLoading,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Contact Phone Number',
        hintText: 'e.g., +1 555-0199',
        prefixIcon: Icon(Icons.phone_outlined),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      enabled: !_isLoading,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Last Known Location *',
        hintText: 'e.g., Central Park, West Entrance',
        prefixIcon: Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Last known location is required.';
        }
        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<PersonStatus>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.info_outline_rounded),
        border: OutlineInputBorder(),
      ),
      items: PersonStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.label),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      enabled: !_isLoading,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Identifying Marks & Description',
        hintText: 'Clothing worn, height, hair color, scars, etc.',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(Icons.description_outlined),
        ),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _handleSave,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline_rounded),
      label: Text(
        _isLoading ? 'Registering Report...' : 'Submit Report',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _resetForm,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.clear_all_rounded),
      label: const Text('Reset Form'),
    );
  }
}