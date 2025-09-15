import 'package:flutter/material.dart';
import '../../models/violation.dart';
import 'report_dialog.dart';
import '../../theme/theme.dart';

class ReportButton extends StatelessWidget {
  final ViolationTargetType targetType;
  final String targetId;
  final String? targetTitle;
  final String? penalizedUserUid;
  final bool isCompact;

  const ReportButton({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.penalizedUserUid,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: () => _showReportDialog(context),
        icon: const Icon(Icons.report_problem, color: NatureColors.errorRed),
        tooltip: 'Report this content',
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: const Icon(Icons.report_problem, size: 16),
      label: const Text('Report'),
      style: OutlinedButton.styleFrom(
        foregroundColor: NatureColors.errorRed,
        side: const BorderSide(color: NatureColors.errorRed),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        targetTitle: targetTitle,
        penalizedUserUid: penalizedUserUid,
      ),
    );
  }
}
