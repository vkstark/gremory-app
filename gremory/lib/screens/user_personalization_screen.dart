import 'package:flutter/material.dart';
import 'dart:convert';

class UserPersonalizationScreen extends StatefulWidget {
  final Map<String, dynamic> basicDetails;
  final Function(Map<String, dynamic>) onSubmit;

  const UserPersonalizationScreen({
    super.key,
    required this.basicDetails,
    required this.onSubmit,
  });

  @override
  State<UserPersonalizationScreen> createState() => _UserPersonalizationScreenState();
}

class _UserPersonalizationScreenState extends State<UserPersonalizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthdateController = TextEditingController();
  final _interestsController = TextEditingController();
  final _goalsController = TextEditingController();
  final _experienceLevelController = TextEditingController();
  final _communicationStyleController = TextEditingController();
  final _onboardingSourceController = TextEditingController();
  final _industryController = TextEditingController();
  final _roleController = TextEditingController();
  final _contentPreferencesController = TextEditingController();
  
  String? _errorMessage;
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    
    // Pre-populate fields if available in basicDetails
    if (widget.basicDetails['birthdate'] != null && widget.basicDetails['birthdate'].isNotEmpty) {
      _birthdateController.text = widget.basicDetails['birthdate'];
      try {
        _selectedDate = DateTime.parse(widget.basicDetails['birthdate']);
      } catch (_) {}
    }
    
    if (widget.basicDetails['interests'] != null) {
      final interests = widget.basicDetails['interests'];
      if (interests is List) {
        _interestsController.text = interests.join(', ');
      }
    }
    
    if (widget.basicDetails['goals'] != null) {
      final goals = widget.basicDetails['goals'];
      if (goals is List) {
        _goalsController.text = goals.join(', ');
      }
    }
    
    _experienceLevelController.text = widget.basicDetails['experience_level'] ?? '';
    _communicationStyleController.text = widget.basicDetails['communication_style'] ?? '';
    _onboardingSourceController.text = widget.basicDetails['onboarding_source'] ?? '';
    _industryController.text = widget.basicDetails['industry'] ?? '';
    _roleController.text = widget.basicDetails['role'] ?? '';
    
    if (widget.basicDetails['content_preferences'] != null) {
      try {
        final preferences = widget.basicDetails['content_preferences'];
        if (preferences is Map) {
          _contentPreferencesController.text = const JsonEncoder.withIndent('  ').convert(preferences);
        } else if (preferences is String) {
          _contentPreferencesController.text = preferences;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _birthdateController.dispose();
    _interestsController.dispose();
    _goalsController.dispose();
    _experienceLevelController.dispose();
    _communicationStyleController.dispose();
    _onboardingSourceController.dispose();
    _industryController.dispose();
    _roleController.dispose();
    _contentPreferencesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),  // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = _formatDate(picked);
      });
    }
  }
  
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize Your Experience'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Error message display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _errorMessage = null),
                        color: Colors.red.shade700,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Personal Information Section
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              TextFormField(
                controller: _birthdateController,
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  hintText: 'YYYY-MM-DD',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                    tooltip: 'Select date',
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Enter a valid date in YYYY-MM-DD format';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Preferences Section
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'Your Preferences',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              TextFormField(
                controller: _interestsController,
                decoration: const InputDecoration(
                  labelText: 'Interests',
                  hintText: 'Comma separated list',
                  helperText: 'E.g., Reading, Music, Travel',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _goalsController,
                decoration: const InputDecoration(
                  labelText: 'Goals',
                  hintText: 'Comma separated list',
                  helperText: 'E.g., Improve skills, Learn a language',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Experience Section
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'Experience & Communication',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              TextFormField(
                controller: _experienceLevelController,
                decoration: const InputDecoration(
                  labelText: 'Experience Level',
                  hintText: 'Select your level of experience',
                  helperText: 'E.g., Beginner, Intermediate, Advanced',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _communicationStyleController,
                decoration: const InputDecoration(
                  labelText: 'Communication Style',
                  hintText: 'How do you prefer to communicate?',
                  helperText: 'E.g., Direct, Visual, Detailed',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Information Section
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              TextFormField(
                controller: _contentPreferencesController,
                decoration: const InputDecoration(
                  labelText: 'Content Preferences (JSON)',
                  hintText: '{"key": "value"}',
                  helperText: 'Enter a valid JSON object or leave blank',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      jsonDecode(value);
                    } catch (e) {
                      return 'Enter valid JSON format';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _onboardingSourceController,
                decoration: const InputDecoration(
                  labelText: 'Onboarding Source',
                  hintText: 'How did you find us?',
                  helperText: 'E.g., Friend, Social Media, Search',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  hintText: 'Your primary industry',
                  helperText: 'E.g., Technology, Healthcare, Education',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'Your job or role',
                  helperText: 'E.g., Developer, Manager, Student',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _errorMessage = null);
                        try {
                          final details = Map<String, dynamic>.from(widget.basicDetails);
                          if (_birthdateController.text.isNotEmpty) details['birthdate'] = _birthdateController.text;
                          if (_interestsController.text.isNotEmpty) details['interests'] = _interestsController.text.split(',').map((e) => e.trim()).toList();
                          if (_goalsController.text.isNotEmpty) details['goals'] = _goalsController.text.split(',').map((e) => e.trim()).toList();
                          if (_experienceLevelController.text.isNotEmpty) details['experience_level'] = _experienceLevelController.text;
                          if (_communicationStyleController.text.isNotEmpty) details['communication_style'] = _communicationStyleController.text;
                          if (_contentPreferencesController.text.isNotEmpty) {
                            try {
                              details['content_preferences'] = jsonDecode(_contentPreferencesController.text);
                            } catch (e) {
                              throw Exception('Content preferences must be valid JSON format');
                            }
                          }
                          if (_onboardingSourceController.text.isNotEmpty) details['onboarding_source'] = _onboardingSourceController.text;
                          if (_industryController.text.isNotEmpty) details['industry'] = _industryController.text;
                          if (_roleController.text.isNotEmpty) details['role'] = _roleController.text;
                          widget.onSubmit(details);
                        } catch (e) {
                          setState(() => _errorMessage = e.toString());
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
