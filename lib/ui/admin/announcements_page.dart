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
      child: Row(
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
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pinned', style: TextStyle(fontSize: 12)),
            selected: _showPinnedOnly,
            onSelected: (selected) {
              setState(() {
                _showPinnedOnly = selected;
              });
            },
            selectedColor: NatureColors.primaryGreen.withAlpha((0.2 * 255).round()),
            checkmarkColor: NatureColors.primaryGreen,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final String author = announcement.createdBy;
    final String authorInitial = (author.isNotEmpty ? author.trim()[0] : 'A').toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAnnouncementDetails(announcement, provider),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
                    child: Text(
                      authorInitial,
                      style: const TextStyle(
                        color: NatureColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: NatureColors.textDark,
                                ),
                              ),
                            ),
                            if (announcement.pinned)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
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
                                    Text('PINNED',
                                      style: TextStyle(color: NatureColors.pureWhite, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
                                      Icon(announcement.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                                        color: NatureColors.primaryGreen, size: 16),
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
                          style: const TextStyle(color: NatureColors.mediumGray, fontSize: 13, height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: NatureColors.textDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(announcement.createdAt),
                          style: const TextStyle(
                            color: NatureColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: NatureColors.textDark,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            announcement.createdBy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NatureColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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
              // Footer actions removed (available in overflow menu)
            ],
          ),
        ),
      )
    );
  }

  void _handleMenuAction(String action, Announcement announcement, AnnouncementProvider provider) {
    switch (action) {
      case 'toggle_pin':
        provider.togglePin(announcement.id);
        break;
      case 'send_push':
        _showConfirmDialog(
          'Send Push Notification',
          'Are you sure you want to send a push notification for this announcement?',
          () => provider.sendPushNotification(announcement.id),
        );
        break;
      case 'edit':
        _showEditAnnouncementDialog(announcement, provider);
        break;
      case 'delete':
        _showConfirmDialog(
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
        onSave: (title, body, pinned, cropTargets, sendPush) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);
          
          announcementProvider.createAnnouncement(
            title: title,
            body: body,
            createdBy: authProvider.currentUser?.email ?? 'Admin',
            pinned: true,
            cropTargets: const [],
            sendPush: false,
          );
        },
      ),
    );
  }

  void _showEditAnnouncementDialog(Announcement announcement, AnnouncementProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        announcement: announcement,
        onSave: (title, body, pinned, cropTargets, sendPush) {
          final updatedAnnouncement = announcement.copyWith(
            title: title,
            body: body,
            pinned: true,
            cropTargets: const [],
          );
          provider.updateAnnouncement(updatedAnnouncement);
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

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NatureColors.errorRed,
            ),
            child: const Text('Confirm'),
          ),
        ],
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
  final Function(String title, String body, bool pinned, List<String> cropTargets, bool sendPush) onSave;

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
  final bool _sendPush = false; // disabled
  List<String> _selectedCrops = [];

  // Admin-friendly features
  String _selectedCategory = 'General';
  String _priority = 'Normal';
  bool _isUrgent = false;
  final List<String> _announcementTemplates = [
    'Weather Alert',
    'Market Update',
    'Training Schedule',
    'Equipment Maintenance',
    'Harvest Reminder',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _bodyController.text = widget.announcement!.body;
      _pinned = true;
      _selectedCrops = const [];
    }
    
    // Add listeners for real-time character count updates
    _titleController.addListener(() {
      setState(() {});
    });
    _bodyController.addListener(() {
      setState(() {});
    });
    
    // Skip loading crops; targeting removed
  }


  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NatureColors.lightGreen,
                  NatureColors.lightGreen.withAlpha((0.8 * 255).round()),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.announcement == null ? Icons.campaign : Icons.edit_note,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                        widget.announcement == null ? 'Create New Announcement' : 'Edit Announcement',
              style: const TextStyle(
                          fontSize: 18,
                fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.announcement == null 
                          ? 'Share updates with farmers'
                          : 'Update announcement details',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ),
              ],
            ),
          ),
            
          // Enhanced Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field with Enhanced Design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.title,
                                color: NatureColors.lightGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Announcement Title',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
            TextField(
              controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter a clear, descriptive title that farmers will understand...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: NatureColors.lightGreen, width: 2),
                            ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            maxLength: 100,
            ),
            const SizedBox(height: 8),
                          Text(
                            '${_titleController.text.length}/100 characters',
                            style: TextStyle(
                              fontSize: 12,
                              color: _titleController.text.length > 80 ? Colors.orange : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Templates Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((0.05 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withAlpha((0.2 * 255).round())),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Quick Templates',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _announcementTemplates.map((template) {
                              final isSelected = _selectedCategory == template;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = template;
                                    _applyTemplate(template);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade600 : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    template,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Message Field with Enhanced Design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.message,
                                  color: NatureColors.lightGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Announcement Message',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
                            decoration: InputDecoration(
                              hintText: 'Write your announcement message here...\n\n💡 Tips for effective announcements:\n• Use clear, simple language\n• Include important details (dates, locations, etc.)\n• Be specific about what farmers need to do\n• Use bullet points for easy reading\n• Keep it concise but informative',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                                height: 1.6,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: NatureColors.lightGreen, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: const TextStyle(fontSize: 16, height: 1.6),
                            maxLines: 10,
                            maxLength: 1000,
            ),
            const SizedBox(height: 8),
            Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                              Text(
                                '${_bodyController.text.length}/1000 characters',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _bodyController.text.length > 800 ? Colors.orange : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${((_bodyController.text.length / 1000) * 100).toInt()}% used',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Enhanced Settings Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            NatureColors.lightGreen.withAlpha((0.05 * 255).round()),
                            NatureColors.lightGreen.withAlpha((0.02 * 255).round()),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
              children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.settings_outlined,
                                  color: NatureColors.lightGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Priority Selection
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      color: _isUrgent ? Colors.red : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Priority Level',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                                    Expanded(
                                      child: _buildPriorityOption('Low', Colors.green, 'Normal'),
                                    ),
                const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildPriorityOption('High', Colors.orange, 'High'),
                                    ),
                const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildPriorityOption('Urgent', Colors.red, 'Urgent'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Enhanced Pin Option
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha((0.05 * 255).round()),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.push_pin,
                                    color: NatureColors.lightGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pin Announcement',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pin to top of announcements list',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _pinned,
                                  onChanged: (value) => setState(() => _pinned = value),
                                  activeColor: NatureColors.lightGreen,
                                  materialTapTargetSize: MaterialTapTargetSize.padded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Enhanced Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                  FilledButton.icon(
                  onPressed: _saveAnnouncement,
                    icon: Icon(
                      widget.announcement == null ? Icons.campaign : Icons.save,
                      size: 16,
                    ),
                    label: Text(
                    widget.announcement == null ? 'Create' : 'Update',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: NatureColors.lightGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                  ),
                ),
              ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildPriorityOption(String label, Color color, String value) {
    final isSelected = _priority == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priority = value;
          _isUrgent = value == 'Urgent';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(String template) {
    switch (template) {
      case 'Weather Alert':
        _titleController.text = 'Weather Alert - Important Update';
        _bodyController.text = 'Dear Farmers,\n\nPlease be advised of the following weather conditions:\n\n• Current conditions: [Describe weather]\n• Expected changes: [Time and conditions]\n• Recommendations: [Safety measures]\n\nStay safe and take necessary precautions.\n\nBest regards,\nAgrimix Team';
        _priority = 'High';
        _isUrgent = true;
        break;
      case 'Market Update':
        _titleController.text = 'Market Update - Price Information';
        _bodyController.text = 'Dear Farmers,\n\nHere are the latest market updates:\n\n• Current prices: [List prices]\n• Market trends: [Upward/Downward]\n• Best selling crops: [List crops]\n• Recommendations: [When to sell]\n\nPlan your harvest and sales accordingly.\n\nBest regards,\nAgrimix Team';
        _priority = 'Normal';
        _isUrgent = false;
        break;
      case 'Training Schedule':
        _titleController.text = 'Training Session - [Topic]';
        _bodyController.text = 'Dear Farmers,\n\nWe are pleased to invite you to our upcoming training session:\n\n• Topic: [Training topic]\n• Date: [Date]\n• Time: [Time]\n• Location: [Venue]\n• What to bring: [Materials needed]\n\nPlease confirm your attendance.\n\nBest regards,\nAgrimix Team';
        _priority = 'Normal';
        _isUrgent = false;
        break;
      case 'Equipment Maintenance':
        _titleController.text = 'Equipment Maintenance Reminder';
        _bodyController.text = 'Dear Farmers,\n\nThis is a reminder about equipment maintenance:\n\n• Equipment: [List equipment]\n• Maintenance due: [Date]\n• Service provider: [Contact info]\n• Cost estimate: [Amount]\n\nPlease schedule your maintenance soon.\n\nBest regards,\nAgrimix Team';
        _priority = 'High';
        _isUrgent = false;
        break;
      case 'Harvest Reminder':
        _titleController.text = 'Harvest Time - [Crop Name]';
        _bodyController.text = 'Dear Farmers,\n\nIt\'s time to prepare for harvest:\n\n• Crop: [Crop name]\n• Harvest window: [Dates]\n• Preparation needed: [Tasks]\n• Storage requirements: [Instructions]\n• Market timing: [Best time to sell]\n\nStart your preparations now.\n\nBest regards,\nAgrimix Team';
        _priority = 'High';
        _isUrgent = false;
        break;
      case 'Custom':
        _titleController.clear();
        _bodyController.clear();
        _priority = 'Normal';
        _isUrgent = false;
        break;
    }
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

    // Add priority indicator to title if urgent
    String finalTitle = _titleController.text.trim();
    if (_isUrgent) {
      finalTitle = '🚨 URGENT: $finalTitle';
    }

    widget.onSave(
      finalTitle,
      _bodyController.text.trim(),
      _pinned,
      _selectedCrops,
      _sendPush,
    );
    Navigator.of(context).pop();
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
    final String author = announcement.createdBy;
    final String authorInitial = (author.isNotEmpty ? author[0] : 'A').toUpperCase();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
                  child: Text(authorInitial, style: const TextStyle(color: NatureColors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: NatureColors.textDark)),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: NatureColors.lightGray),
                          const SizedBox(width: 4),
                          Text(_formatDate(announcement.createdAt), style: const TextStyle(fontSize: 12, color: NatureColors.lightGray)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (announcement.pinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: NatureColors.primaryGreen, borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.push_pin, color: NatureColors.pureWhite, size: 10), SizedBox(width: 2), Text('PINNED', style: TextStyle(color: NatureColors.pureWhite, fontSize: 7, fontWeight: FontWeight.bold))],
                    ),
                  ),
                if (announcement.pinned) const SizedBox(width: 4),
                Expanded(
                  child: Text(announcement.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NatureColors.textDark), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(announcement.body, style: const TextStyle(color: NatureColors.mediumGray, fontSize: 14, height: 1.5)),
            const SizedBox(height: 10),
            if (announcement.cropTargets.isNotEmpty) ...[
              const Text('Target Crops:', style: TextStyle(fontWeight: FontWeight.bold, color: NatureColors.textDark, fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: announcement.cropTargets
                    .map((crop) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round())),
                          ),
                          child: Text(crop, style: const TextStyle(color: NatureColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.person, size: 12, color: NatureColors.lightGray), SizedBox(width: 3)],
                ),
                Text(announcement.createdBy, style: const TextStyle(color: NatureColors.lightGray, fontSize: 11)),
                if (announcement.pushSent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: NatureColors.successGreen.withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.notifications_active, color: NatureColors.successGreen, size: 10), SizedBox(width: 2), Text('PUSH SENT', style: TextStyle(color: NatureColors.successGreen, fontSize: 8, fontWeight: FontWeight.bold))],
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
                  style: ElevatedButton.styleFrom(backgroundColor: NatureColors.primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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
