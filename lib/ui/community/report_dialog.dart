import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/moderation_provider.dart';
import '../../models/violation.dart';
import '../../theme/theme.dart';

class ReportDialog extends StatefulWidget {
  final ViolationTargetType targetType;
  final String targetId;
  final String? targetTitle;
  final String? penalizedUserUid;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.penalizedUserUid,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = '';
  bool _isLoading = false;

  final List<String> _predefinedReasons = [
    'Inappropriate content',
    'Spam or misleading information',
    'Harassment or bullying',
    'Violence or dangerous content',
    'Hate speech',
    'Copyright violation',
    'Other',
  ];

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
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.report_problem, color: NatureColors.errorRed),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Report Content',
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
            
            // Content info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NatureColors.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporting: ${_getTargetTypeText(widget.targetType)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.targetTitle != null) ...[
                    const SizedBox(height: 4),
                    Text('Title: ${widget.targetTitle}'),
                  ],
                  const SizedBox(height: 4),
                  Text('ID: ${widget.targetId}'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reason selection
            const Text(
              'Why are you reporting this content?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Predefined reasons
            ..._predefinedReasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                });
              },
            )).toList(),
            
            const SizedBox(height: 16),
            
            // Custom reason
            if (_selectedReason == 'Other') ...[
              const Text(
                'Please provide more details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: NatureColors.primaryGreen),
                  ),
                ),
                maxLines: 3,
              ),
            ],
            
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
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.errorRed,
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
                      : const Text('Submit Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetTypeText(ViolationTargetType type) {
    switch (type) {
      case ViolationTargetType.post:
        return 'Post';
      case ViolationTargetType.comment:
        return 'Comment';
      case ViolationTargetType.recipe:
        return 'Recipe';
      case ViolationTargetType.user:
        return 'User';
    }
  }

  Future<void> _submitReport() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: NatureColors.warning,
        ),
      );
      return;
    }

    if (_selectedReason == 'Other' && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details for your report'),
          backgroundColor: NatureColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reason = _selectedReason == 'Other' 
          ? _reasonController.text.trim()
          : _selectedReason;

      await context.read<ModerationProvider>().reportViolationAndNotify(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: reason,
        reporterUid: 'current_user_id', // In real app, get from auth provider
        penalizedUserUid: widget.penalizedUserUid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you for helping keep our community safe.'),
            backgroundColor: NatureColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
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
