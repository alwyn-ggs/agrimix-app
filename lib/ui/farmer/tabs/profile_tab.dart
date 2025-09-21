import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/messaging_service.dart';
import '../../../theme/theme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _membershipController;
  bool _saving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentAppUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _membershipController = TextEditingController(text: user?.membershipId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _membershipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentAppUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom - 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: NatureColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: NatureColors.primaryGreen,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: NatureColors.primaryGreen),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: NatureColors.primaryGreen,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: NatureColors.primaryGreen),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _membershipController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: NatureColors.primaryGreen,
                      decoration: InputDecoration(
                        labelText: 'Membership ID (optional)',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: NatureColors.primaryGreen),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : () => _saveProfile(context),
                            child: _saving
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _status!.contains('Failed') || _status!.contains('error') 
                              ? Colors.red.shade50 
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _status!.contains('Failed') || _status!.contains('error') 
                                ? Colors.red.shade200 
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          _status!,
                          style: TextStyle(
                            color: _status!.contains('Failed') || _status!.contains('error') 
                                ? Colors.red.shade700 
                                : Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // First row - buttons that can wrap
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 400;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: isWide ? null : double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _syncCurrentToken(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black26),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                              icon: const Icon(Icons.sync, color: Colors.black87, size: 18),
                              label: const Text('Sync Token'),
                            ),
                          ),
                          SizedBox(
                            width: isWide ? null : double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _requestNotifPermission(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black26),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                              icon: const Icon(Icons.notifications_active_outlined, color: Colors.black87, size: 18),
                              label: const Text('Request Permission'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => auth.signOut(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) {
      setState(() { _saving = true; _status = null; });
    }
    final auth = context.read<AuthProvider>();
    final u = auth.currentAppUser!;
    try {
      final updated = u.copyWith(
        name: _nameController.text.trim(),
        membershipId: _membershipController.text.trim().isEmpty ? null : _membershipController.text.trim(),
      );
      await context.read<AuthProvider>().usersRepo.updateUser(updated);
      await auth.refreshCurrentUser();
      if (mounted) {
        setState(() { _status = 'Profile updated.'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'Failed to update: $e'; });
      }
    } finally {
      if (mounted) {
        setState(() { _saving = false; });
      }
    }
  }

  Future<void> _syncCurrentToken(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final messaging = context.read<MessagingService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await messaging.saveTokenToUser(uid, token);
        await auth.refreshCurrentUser();
        if (mounted) {
          setState(() { _status = 'Token synced.'; });
        }
      } else {
        if (mounted) {
          setState(() { _status = 'No token available.'; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'Token sync failed: $e'; });
      }
    }
  }

  Future<void> _requestNotifPermission(BuildContext context) async {
    final messaging = context.read<MessagingService>();
    try {
      await messaging.requestPermission();
      if (mounted) {
        setState(() { _status = 'Notification permission requested.'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'Permission request failed: $e'; });
      }
    }
  }
}