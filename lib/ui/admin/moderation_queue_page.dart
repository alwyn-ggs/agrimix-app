import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/moderation_provider.dart';
import '../../models/violation.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../theme/theme.dart';
import 'moderation_action_dialog.dart';

class ModerationQueuePage extends StatefulWidget {
  const ModerationQueuePage({super.key});

  @override
  State<ModerationQueuePage> createState() => _ModerationQueuePageState();
}

class _ModerationQueuePageState extends State<ModerationQueuePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Moderation Queue'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        bottom: TabBar(
          controller: _tabController,
          labelColor: NatureColors.pureWhite,
          unselectedLabelColor: NatureColors.lightGray,
          indicatorColor: NatureColors.pureWhite,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.report_problem, size: 18),
                  const SizedBox(width: 8),
                  Text('Open (${context.watch<ModerationProvider>().openViolationsCount})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Text('Resolved (${context.watch<ModerationProvider>().resolvedViolationsCount})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel, size: 18),
                  const SizedBox(width: 8),
                  Text('Dismissed (${context.watch<ModerationProvider>().dismissedViolationsCount})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViolationsList(ViolationStatus.open),
          _buildViolationsList(ViolationStatus.resolved),
          _buildViolationsList(ViolationStatus.dismissed),
        ],
      ),
    );
  }

  Widget _buildViolationsList(ViolationStatus status) {
    return Consumer<ModerationProvider>(
      builder: (context, moderationProvider, child) {
        if (moderationProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (moderationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: NatureColors.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Error: ${moderationProvider.error}',
                  style: const TextStyle(color: NatureColors.errorRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => moderationProvider.refreshViolations(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final violations = status == ViolationStatus.open
            ? moderationProvider.openViolations
            : status == ViolationStatus.resolved
                ? moderationProvider.resolvedViolations
                : moderationProvider.dismissedViolations;

        if (violations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == ViolationStatus.open ? Icons.inbox : Icons.check_circle,
                  size: 64,
                  color: NatureColors.lightGray,
                ),
                const SizedBox(height: 16),
                Text(
                  status == ViolationStatus.open
                      ? 'No open violations'
                      : status == ViolationStatus.resolved
                          ? 'No resolved violations'
                          : 'No dismissed violations',
                  style: const TextStyle(
                    fontSize: 16,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: violations.length,
          itemBuilder: (context, index) {
            final violation = violations[index];
            return _buildViolationCard(violation, status);
          },
        );
      },
    );
  }

  Widget _buildViolationCard(Violation violation, ViolationStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getViolationIcon(violation.targetType),
                  color: _getViolationColor(violation.targetType),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getViolationTypeText(violation.targetType),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(violation.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Reason
            Text(
              'Reason: ${violation.reason}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            // Target ID
            Text(
              'Target ID: ${violation.targetId}',
              style: TextStyle(
                fontSize: 12,
                color: NatureColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            
            // Timestamp
            Text(
              'Reported: ${_formatDate(violation.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: NatureColors.mediumGray,
              ),
            ),
            
            // Action taken (if resolved)
            if (violation.actionTaken != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActionColor(violation.actionTaken!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getActionIcon(violation.actionTaken!),
                      color: _getActionColor(violation.actionTaken!),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Action: ${_getActionText(violation.actionTaken!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getActionColor(violation.actionTaken!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action reason (if available)
            if (violation.actionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${violation.actionReason}',
                style: TextStyle(
                  fontSize: 12,
                  color: NatureColors.mediumGray,
                ),
              ),
            ],
            
            // Ban expiration (if banned)
            if (violation.banExpiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ban expires: ${_formatDate(violation.banExpiresAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: NatureColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // Actions (only for open violations)
            if (status == ViolationStatus.open) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showModerationDialog(violation),
                      icon: const Icon(Icons.gavel, size: 16),
                      label: const Text('Take Action'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NatureColors.primaryGreen,
                        side: const BorderSide(color: NatureColors.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dismissViolation(violation),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NatureColors.mediumGray,
                        side: const BorderSide(color: NatureColors.mediumGray),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ViolationStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ViolationStatus.open:
        color = NatureColors.warning;
        text = 'Open';
        break;
      case ViolationStatus.resolved:
        color = NatureColors.successGreen;
        text = 'Resolved';
        break;
      case ViolationStatus.dismissed:
        color = NatureColors.mediumGray;
        text = 'Dismissed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getViolationIcon(ViolationTargetType type) {
    switch (type) {
      case ViolationTargetType.post:
        return Icons.article;
      case ViolationTargetType.comment:
        return Icons.comment;
      case ViolationTargetType.recipe:
        return Icons.restaurant_menu;
      case ViolationTargetType.user:
        return Icons.person;
    }
  }

  Color _getViolationColor(ViolationTargetType type) {
    switch (type) {
      case ViolationTargetType.post:
        return NatureColors.infoBlue;
      case ViolationTargetType.comment:
        return NatureColors.primaryGreen;
      case ViolationTargetType.recipe:
        return NatureColors.warning;
      case ViolationTargetType.user:
        return NatureColors.errorRed;
    }
  }

  String _getViolationTypeText(ViolationTargetType type) {
    switch (type) {
      case ViolationTargetType.post:
        return 'Reported Post';
      case ViolationTargetType.comment:
        return 'Reported Comment';
      case ViolationTargetType.recipe:
        return 'Reported Recipe';
      case ViolationTargetType.user:
        return 'Reported User';
    }
  }

  IconData _getActionIcon(ViolationAction action) {
    switch (action) {
      case ViolationAction.dismiss:
        return Icons.cancel;
      case ViolationAction.warn:
        return Icons.warning;
      case ViolationAction.delete:
        return Icons.delete;
      case ViolationAction.ban:
        return Icons.block;
    }
  }

  Color _getActionColor(ViolationAction action) {
    switch (action) {
      case ViolationAction.dismiss:
        return NatureColors.mediumGray;
      case ViolationAction.warn:
        return NatureColors.warning;
      case ViolationAction.delete:
        return NatureColors.errorRed;
      case ViolationAction.ban:
        return NatureColors.errorRed;
    }
  }

  String _getActionText(ViolationAction action) {
    switch (action) {
      case ViolationAction.dismiss:
        return 'Dismissed';
      case ViolationAction.warn:
        return 'User Warned';
      case ViolationAction.delete:
        return 'Content Deleted';
      case ViolationAction.ban:
        return 'User Banned';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showModerationDialog(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => ModerationActionDialog(violation: violation),
    );
  }

  void _dismissViolation(Violation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Violation'),
        content: const Text('Are you sure you want to dismiss this violation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ModerationProvider>().dismissViolation(
                  violation.id,
                  'admin_id', // In real app, get from auth provider
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Violation dismissed successfully'),
                      backgroundColor: NatureColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error dismissing violation: $e'),
                      backgroundColor: NatureColors.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: NatureColors.mediumGray),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
