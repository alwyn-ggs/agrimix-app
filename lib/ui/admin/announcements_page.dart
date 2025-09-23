import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/announcement.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  String _searchQuery = '';
  bool _showPinnedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(child: _buildAnnouncementsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAnnouncementDialog(context),
        backgroundColor: NatureColors.primaryGreen,
        child: const Icon(Icons.add, color: NatureColors.pureWhite),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: NatureColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: NatureColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 8),
          const Text(
            'Announcements Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: NatureColors.textDark,
            ),
          ),
          const Spacer(),
          Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(NatureColors.primaryGreen),
                  ),
                );
              }
              return Text(
                '${provider.items.length} items',
                style: const TextStyle(
                  color: NatureColors.mediumGray,
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: NatureColors.pureWhite,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, color: NatureColors.mediumGray, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: NatureColors.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: NatureColors.primaryGreen),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ],
          ),
          Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: provider.isLoading ? 4 : 0,
                margin: const EdgeInsets.only(top: 8),
                child: provider.isLoading
                    ? const LinearProgressIndicator(minHeight: 4)
                    : const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, child) {
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: NatureColors.errorRed,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading announcements',
                  style: TextStyle(
                    color: NatureColors.errorRed,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NatureColors.mediumGray),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.clearError(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredAnnouncements = _getFilteredAnnouncements(provider.items);

        if (filteredAnnouncements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: NatureColors.mediumGray,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _showPinnedOnly
                      ? 'No announcements match your filters'
                      : 'No announcements yet',
                  style: const TextStyle(
                    color: NatureColors.mediumGray,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty || _showPinnedOnly
                      ? 'Try adjusting your search or filters'
                      : 'Create your first announcement to get started',
                  style: const TextStyle(
                    color: NatureColors.lightGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredAnnouncements.length,
          itemBuilder: (context, index) {
            final announcement = filteredAnnouncements[index];
            return _buildAnnouncementCard(announcement, provider);
          },
        );
      },
    );
  }

  List<Announcement> _getFilteredAnnouncements(List<Announcement> announcements) {
    List<Announcement> filtered = announcements;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((announcement) =>
          announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          announcement.body.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filter by pinned status
    if (_showPinnedOnly) {
      filtered = filtered.where((announcement) => announcement.pinned).toList();
    }

    // Sort: pinned first, then by creation date
    filtered.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Widget _buildAnnouncementCard(Announcement announcement, AnnouncementProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showAnnouncementDetails(announcement, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (announcement.pinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NatureColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, color: NatureColors.pureWhite, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'PINNED',
                            style: TextStyle(
                              color: NatureColors.pureWhite,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (announcement.pinned) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 18,
                    onSelected: (value) => _handleMenuAction(value, announcement, provider),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_pin',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              announcement.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                              color: NatureColors.primaryGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(announcement.pinned ? 'Unpin' : 'Pin', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'send_push',
                        enabled: !announcement.pushSent,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active, color: NatureColors.primaryGreen, size: 16),
                            SizedBox(width: 6),
                            Text('Send Push', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: NatureColors.primaryGreen, size: 16),
                            SizedBox(width: 6),
                            Text('Edit', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: NatureColors.errorRed, size: 16),
                            SizedBox(width: 6),
                            Text('Delete', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                announcement.body,
                style: const TextStyle(
                  color: NatureColors.mediumGray,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: NatureColors.lightGray,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: const TextStyle(
                          color: NatureColors.lightGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        size: 12,
                        color: NatureColors.lightGray,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          announcement.createdBy,
                          style: const TextStyle(
                            color: NatureColors.lightGray,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (announcement.cropTargets.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${announcement.cropTargets.length} crops',
                        style: const TextStyle(
                          color: NatureColors.primaryGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (announcement.pushSent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NatureColors.successGreen.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: NatureColors.successGreen,
                            size: 10,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'PUSHED',
                            style: TextStyle(
                              color: NatureColors.successGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Announcement announcement, AnnouncementProvider provider) {
    switch (action) {
      case 'toggle_pin':
        provider.togglePin(announcement.id);
        break;
      case 'send_push':
        _showConfirmDialogAsync(
          'Send Push Notification',
          'Are you sure you want to send a push notification for this announcement?',
          () => provider.sendPushNotification(announcement.id),
        );
        break;
      case 'edit':
        _showEditAnnouncementDialog(announcement, provider);
        break;
      case 'delete':
        _showConfirmDialogAsync(
          'Delete Announcement',
          'Are you sure you want to delete this announcement? This action cannot be undone.',
          () => provider.deleteAnnouncement(announcement.id),
        );
        break;
    }
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        onSave: (title, body, pinned, cropTargets) async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);
          
          // Show uploading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading announcement...'),
              backgroundColor: NatureColors.lightGreen,
              duration: Duration(seconds: 2),
            ),
          );

          final ok = await announcementProvider.createAnnouncement(
            title: title,
            body: body,
            createdBy: authProvider.currentUser?.email ?? 'Admin',
            pinned: true,
            cropTargets: const [],
            sendPush: false,
          );

          // Show result
          if (ok) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement uploaded successfully'),
                  backgroundColor: NatureColors.primaryGreen,
                ),
              );
            }
          } else {
            if (context.mounted) {
              final providerErr = Provider.of<AnnouncementProvider>(context, listen: false).error;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(providerErr != null && providerErr.isNotEmpty
                      ? 'Failed to upload: $providerErr'
                      : 'Failed to upload announcement'),
                  backgroundColor: NatureColors.errorRed,
                ),
              );
            }
          }
          return ok;
        },
      ),
    );
  }

  void _showEditAnnouncementDialog(Announcement announcement, AnnouncementProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        announcement: announcement,
        onSave: (title, body, pinned, cropTargets) async {
          final updatedAnnouncement = announcement.copyWith(
            title: title,
            body: body,
            pinned: true,
            cropTargets: const [],
          );
          final ok = await provider.updateAnnouncement(updatedAnnouncement);
          return ok;
        },
      ),
    );
  }

  void _showAnnouncementDetails(Announcement announcement, AnnouncementProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementDetailsDialog(announcement: announcement),
    );
  }

  void _showConfirmDialogAsync(String title, String message, Future<bool> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool localLoading = false;
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 8),
                if (localLoading) const LinearProgressIndicator(minHeight: 3),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: localLoading
                    ? null
                    : () async {
                        setState(() => localLoading = true);
                        final ok = await onConfirm();
                        if (mounted) Navigator.of(context).pop();
                        if (mounted) {
                          final err = Provider.of<AnnouncementProvider>(context, listen: false).error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Operation completed' : (err?.isNotEmpty == true ? err! : 'Operation failed')),
                              backgroundColor: ok ? NatureColors.primaryGreen : NatureColors.errorRed,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: NatureColors.errorRed),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class AnnouncementFormDialog extends StatefulWidget {
  final Announcement? announcement;
  final Future<bool> Function(String title, String body, bool pinned, List<String> cropTargets) onSave;

  const AnnouncementFormDialog({
    super.key,
    this.announcement,
    required this.onSave,
  });

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _pinned = true; // forced pinned
  List<String> _selectedCrops = [];
  List<String> _availableCrops = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _bodyController.text = widget.announcement!.body;
      _pinned = true;
      _selectedCrops = const [];
    }
    // Skip loading crops; targeting removed
  }

  Future<void> _loadAvailableCrops() async {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    final crops = await provider.getAvailableCropTargets();
    setState(() {
      _availableCrops = crops;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              widget.announcement == null ? 'Create Announcement' : 'Edit Announcement',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NatureColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Announcement Title',
                hintText: 'Enter a concise title',
                labelStyle: TextStyle(fontSize: 13),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen),
                ),
                isDense: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Write the announcement message that all users will see...',
                labelStyle: TextStyle(fontSize: 13),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen),
                ),
                isDense: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, height: 1.4),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This announcement will be pinned and sent to Notifications (bell) for all users.',
              style: TextStyle(fontSize: 12, color: NatureColors.mediumGray),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _saveAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    _submitting
                        ? 'Saving...'
                        : (widget.announcement == null ? 'Create' : 'Update'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAnnouncement() {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: NatureColors.errorRed,
        ),
      );
      return;
    }
    if (_submitting) return;
    setState(() { _submitting = true; });
    widget.onSave(
      _titleController.text.trim(),
      _bodyController.text.trim(),
      _pinned,
      _selectedCrops,
    ).then((ok) {
      if (mounted) {
        setState(() { _submitting = false; });
        if (ok) {
          Navigator.of(context).pop();
        }
      }
    }).catchError((_) {
      if (mounted) setState(() { _submitting = false; });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}

class AnnouncementDetailsDialog extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailsDialog({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (announcement.pinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: NatureColors.primaryGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, color: NatureColors.pureWhite, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'PINNED',
                          style: TextStyle(
                            color: NatureColors.pureWhite,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (announcement.pinned) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NatureColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              style: const TextStyle(
                color: NatureColors.mediumGray,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            if (announcement.cropTargets.isNotEmpty) ...[
              const Text(
                'Target Crops:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NatureColors.textDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: announcement.cropTargets.map((crop) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round())),
                    ),
                    child: Text(
                      crop,
                      style: const TextStyle(
                        color: NatureColors.primaryGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: NatureColors.lightGray,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Created ${_formatDate(announcement.createdAt)}',
                      style: const TextStyle(
                        color: NatureColors.lightGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: NatureColors.lightGray,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      announcement.createdBy,
                      style: const TextStyle(
                        color: NatureColors.lightGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (announcement.pushSent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: NatureColors.successGreen.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: NatureColors.successGreen,
                          size: 10,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'PUSH SENT',
                          style: TextStyle(
                            color: NatureColors.successGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
