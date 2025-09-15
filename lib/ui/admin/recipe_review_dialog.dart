import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../theme/theme.dart';

class RecipeReviewDialog extends StatefulWidget {
  final Recipe recipe;
  final String action; // 'approve', 'reject', 'mark_standard', 'delete'
  final Function(String reason) onConfirm;

  const RecipeReviewDialog({
    super.key,
    required this.recipe,
    required this.action,
    required this.onConfirm,
  });

  @override
  State<RecipeReviewDialog> createState() => _RecipeReviewDialogState();
}

class _RecipeReviewDialogState extends State<RecipeReviewDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getActionIcon(), color: _getActionColor()),
          const SizedBox(width: 8),
          Text(_getActionTitle()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipe: ${widget.recipe.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Method: ${widget.recipe.method.name} | Target: ${widget.recipe.cropTarget}',
            style: const TextStyle(color: NatureColors.darkGray),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: _getReasonLabel(),
              hintText: _getReasonHint(),
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: NatureColors.primaryGreen),
              ),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(),
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
              : Text(_getActionButtonText()),
        ),
      ],
    );
  }

  IconData _getActionIcon() {
    switch (widget.action) {
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'mark_standard':
        return Icons.star;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor() {
    switch (widget.action) {
      case 'approve':
        return NatureColors.primaryGreen;
      case 'reject':
        return Colors.red;
      case 'mark_standard':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return NatureColors.darkGray;
    }
  }

  String _getActionTitle() {
    switch (widget.action) {
      case 'approve':
        return 'Approve Recipe';
      case 'reject':
        return 'Reject Recipe';
      case 'mark_standard':
        return 'Mark as Standard';
      case 'delete':
        return 'Delete Recipe';
      default:
        return 'Recipe Action';
    }
  }

  String _getReasonLabel() {
    switch (widget.action) {
      case 'approve':
        return 'Approval Reason (Optional)';
      case 'reject':
        return 'Rejection Reason *';
      case 'mark_standard':
        return 'Reason for Marking as Standard (Optional)';
      case 'delete':
        return 'Deletion Reason *';
      default:
        return 'Reason';
    }
  }

  String _getReasonHint() {
    switch (widget.action) {
      case 'approve':
        return 'Why is this recipe being approved?';
      case 'reject':
        return 'Why is this recipe being rejected?';
      case 'mark_standard':
        return 'Why should this recipe be marked as standard?';
      case 'delete':
        return 'Why is this recipe being deleted?';
      default:
        return 'Enter reason...';
    }
  }

  String _getActionButtonText() {
    switch (widget.action) {
      case 'approve':
        return 'Approve';
      case 'reject':
        return 'Reject';
      case 'mark_standard':
        return 'Mark Standard';
      case 'delete':
        return 'Delete';
      default:
        return 'Confirm';
    }
  }

  void _handleConfirm() async {
    if (widget.action == 'reject' || widget.action == 'delete') {
      if (_reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reason is required for this action'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(_reasonController.text.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
