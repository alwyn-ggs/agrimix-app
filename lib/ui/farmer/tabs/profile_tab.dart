import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../services/messaging_service.dart';
import '../../../services/storage_service.dart';
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
  bool _uploadingPhoto = false;
  bool _removingPhoto = false;
  String? _status;
  File? _localPhoto;

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
          // Header card with avatar and basic info
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: NatureColors.primaryGreen.withAlpha((0.15 * 255).round()),
                        backgroundImage: _localPhoto != null
                            ? FileImage(_localPhoto!)
                            : (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                ? NetworkImage(user.photoUrl!) as ImageProvider
                                : null,
                        child: (user.photoUrl == null || user.photoUrl!.isEmpty) && _localPhoto == null
                            ? const Icon(Icons.person, size: 36, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isEmpty ? 'Unnamed User' : user.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploadingPhoto ? null : () => _pickAndUploadPhoto(context),
                        icon: _uploadingPhoto
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Change photo'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: NatureColors.primaryGreen,
                          side: BorderSide(color: NatureColors.primaryGreen.withAlpha((0.4 * 255).round())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _removingPhoto || ((user.photoUrl == null || user.photoUrl!.isEmpty) && _localPhoto == null)
                            ? null
                            : () => _removePhoto(context),
                        icon: _removingPhoto
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withAlpha((0.4 * 255).round())),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Notifications & Device',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (xFile == null) return;
      final file = File(xFile.path);
      if (mounted) {
        setState(() { _localPhoto = file; _uploadingPhoto = true; _status = null; });
      }

      final storage = context.read<StorageService>();
      final uid = auth.currentUser?.uid;
      if (uid == null) throw Exception('No user');
      final url = await storage.uploadProfileImage(imageFile: file, userId: uid);

      final u = auth.currentAppUser!;
      final updated = u.copyWith(photoUrl: url);
      await context.read<AuthProvider>().usersRepo.updateUser(updated);
      await auth.refreshCurrentUser();
      if (mounted) {
        setState(() { _status = 'Profile photo updated.'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'Photo upload failed: $e'; });
      }
    } finally {
      if (mounted) {
        setState(() { _uploadingPhoto = false; });
      }
    }
  }

  Future<void> _removePhoto(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    try {
      if (mounted) {
        setState(() { _removingPhoto = true; _status = null; });
      }

      final storage = context.read<StorageService>();
      final currentUrl = auth.currentAppUser?.photoUrl;
      if (currentUrl != null && currentUrl.isNotEmpty) {
        try {
          await storage.deleteFileByUrl(currentUrl);
        } catch (_) {
          // Non-fatal: if deletion fails, still clear reference
        }
      }

      final u = auth.currentAppUser!;
      final updated = u.copyWith(photoUrl: null);
      await context.read<AuthProvider>().usersRepo.updateUser(updated);
      await auth.refreshCurrentUser();
      if (mounted) {
        setState(() { _localPhoto = null; _status = 'Profile photo removed.'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'Failed to remove photo: $e'; });
      }
    } finally {
      if (mounted) {
        setState(() { _removingPhoto = false; });
      }
    }
  }
}