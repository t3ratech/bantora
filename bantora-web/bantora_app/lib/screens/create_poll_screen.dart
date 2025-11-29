import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreatePollScreen extends StatefulWidget {
  final ApiService apiService;

  const CreatePollScreen({super.key, required this.apiService});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  String _selectedScope = 'NATIONAL';
  bool _creating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _creating = true);

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final poll = await widget.apiService.createPoll(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scope: _selectedScope,
      options: options,
    );

    setState(() => _creating = false);

    if (!mounted) return;

    if (poll != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poll created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create poll. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Poll'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Poll Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 10) {
                  return 'Title must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Scope
            DropdownButtonFormField<String>(
              value: _selectedScope,
              decoration: const InputDecoration(
                labelText: 'Poll Scope',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              items: const [
                DropdownMenuItem(value: 'NATIONAL', child: Text('National')),
                DropdownMenuItem(value: 'SADC', child: Text('SADC Region')),
                DropdownMenuItem(value: 'ECOWAS', child: Text('ECOWAS Region')),
                DropdownMenuItem(value: 'EAC', child: Text('EAC Region')),
                DropdownMenuItem(value: 'AU', child: Text('African Union')),
                DropdownMenuItem(value: 'CONTINENTAL', child: Text('Continental')),
              ],
              onChanged: (value) {
                setState(() => _selectedScope = value!);
              },
            ),
            const SizedBox(height: 24),

            // Options Header
            Row(
              children: [
                const Text(
                  'Poll Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _optionControllers.length < 10 ? _addOption : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Options List
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.check_box_outline_blank),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an option';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Create Button
            ElevatedButton(
              onPressed: _creating ? null : _createPoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _creating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'CREATE POLL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
