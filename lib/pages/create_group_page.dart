import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupPage extends StatefulWidget {
  final DocumentSnapshot? groupDoc;
  const CreateGroupPage({super.key, this.groupDoc});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool get isEditMode => widget.groupDoc != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final data = widget.groupDoc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
      };

      if (isEditMode) {
        await widget.groupDoc!.reference.update(data);
      } else {
        await FirebaseFirestore.instance.collection('groups').add({
          ...data,
          'owner': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'members': [user.uid],
        });
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isEditMode ? 'Edit' : 'Create'} failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Group' : 'Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a group name'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(isEditMode ? Icons.save : Icons.group_add),
                      label: Text(isEditMode ? 'Save Changes' : 'Create'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
