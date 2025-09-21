import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/moderation_provider.dart';
import '../../models/violation.dart';
import '../../theme/theme.dart';

class ModerationActionDialog extends StatefulWidget {
  final Violation violation;

  const ModerationActionDialog({
    super.key,
    required this.violation,
  });

  @override
  State<ModerationActionDialog> createState() => _ModerationActionDialogState();
}

class _ModerationActionDialogState extends State<ModerationActionDialog> {
  ViolationAction? _selectedAction;
  final TextEditingController _reasonController = TextEditingController();
  int _banDays = 7;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.gavel, color: NatureColors.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Moderation Action',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Violation details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NatureColors.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Violation Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${_getViolationTypeText(widget.violation.targetType)}'),
                  Text('Target ID: ${widget.violation.targetId}'),
                  Text('Reason: ${widget.violation.reason}'),
                  Text('Reported: ${_formatDate(widget.violation.createdAt)}'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action selection
            const Text(
              'Select Action',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Action options
            _buildActionOption(
              ViolationAction.warn,
              Icons.warning,
              'Warn User',
              'Send a warning message to the user',
              NatureColors.warning,
            ),
            _buildActionOption(
              ViolationAction.delete,
              Icons.delete,
              'Delete Content',
              'Remove the reported content',
              NatureColors.errorRed,
            ),
            _buildActionOption(
              ViolationAction.ban,
              Icons.block,
              'Temporary Ban',
              'Suspend user account temporarily',
              NatureColors.errorRed,
            ),
            
            const SizedBox(height: 20),
            
            // Ban duration (if ban selected)
            if (_selectedAction == ViolationAction.ban) ...[
              const Text(
                'Ban Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _banDays.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_banDays days',
                      onChanged: (value) {
                        setState(() {
                          _banDays = value.round();
                        });
                      },
                    ),
                  ),
                  Text('$_banDays days'),
                ],
              ),
            ],
            
            // Reason input
            const SizedBox(height: 20),
            const Text(
              'Action Reason',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason for this action...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NatureColors.primaryGreen),
                ),
              ),
              maxLines: 3,
            ),
            
            const Spacer(),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _executeAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionColor(_selectedAction),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Execute Action'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption(
    ViolationAction action,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    final isSelected = _selectedAction == action;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(description),
        onTap: () {
          setState(() {
            _selectedAction = action;
          });
        },
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      ),
    );
  }

  Color _getActionColor(ViolationAction? action) {
    switch (action) {
      case ViolationAction.warn:
        return NatureColors.warning;
      case ViolationAction.delete:
        return NatureColors.errorRed;
      case ViolationAction.ban:
        return NatureColors.errorRed;
      default:
        return NatureColors.primaryGreen;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _executeAction() async {
    if (_selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an action'),
          backgroundColor: NatureColors.warning,
        ),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for this action'),
          backgroundColor: NatureColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final moderationProvider = context.read<ModerationProvider>();
      final reason = _reasonController.text.trim();

      switch (_selectedAction!) {
        case ViolationAction.warn:
          await moderationProvider.warnUser(
            widget.violation.id,
            'admin_id', // In real app, get from auth provider
            warningMessage: reason,
          );
          break;
        case ViolationAction.delete:
          await moderationProvider.deleteContent(
            widget.violation.id,
            'admin_id', // In real app, get from auth provider
            reason: reason,
          );
          break;
        case ViolationAction.ban:
          await moderationProvider.banUser(
            widget.violation.id,
            'admin_id', // In real app, get from auth provider
            reason: reason,
            banDuration: Duration(days: _banDays),
          );
          break;
        case ViolationAction.dismiss:
          // This shouldn't happen as dismiss is handled separately
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action executed successfully'),
            backgroundColor: NatureColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error executing action: $e'),
            backgroundColor: NatureColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
