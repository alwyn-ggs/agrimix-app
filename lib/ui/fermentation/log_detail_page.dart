import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../repositories/fermentation_repo.dart';
import '../../models/fermentation_log.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class LogDetailPage extends StatelessWidget {
  const LogDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final logId = args?['id'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Fermentation', style: TextStyle(color: Colors.white))),
      backgroundColor: Colors.white,
      body: logId == null
          ? const Center(child: Text('No log'))
          : FutureBuilder<FermentationLog?>(
              future: context.read<FermentationRepo>().getFermentationLog(logId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final log = snap.data!;
                return _Detail(log: log);
              },
            ),
    );
  }
}

class _Detail extends StatefulWidget {
  final FermentationLog log;
  const _Detail({required this.log});

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  late FermentationLog _log;
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _notes.text = _log.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh the log data
        final repo = context.read<FermentationRepo>();
        final updatedLog = await repo.getFermentationLog(_log.id);
        if (updatedLog != null) {
          setState(() {
            _log = updatedLog;
            _notes.text = _log.notes ?? '';
          });
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _log.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_log.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _log.status.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _log.method.name,
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: _log.alertsEnabled,
                            onChanged: (v) async {
                              await context.read<FermentationRepo>().toggleFermentationAlerts(_log.id, v);
                              if (mounted) {
                                setState(() => _log = _log.copyWith(alertsEnabled: v));
                                if (v) {
                                  await context.read<NotificationService>().scheduleFermentationNotifications(
                                        _log.id,
                                        _log.title,
                                        _log.stages.map((s) => s.toMap()).toList(),
                                        _log.startAt,
                                      );
                                } else {
                                  await context.read<NotificationService>().cancelFermentationNotifications(_log.id);
                                }
                              }
                            },
                          ),
                          const Text('Alerts', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Started: ${_formatDateTime(_log.startAt)}'),
                    ],
                  ),
                  if (_log.recipeId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Linked to recipe: ${_log.recipeId}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _log.stages.isEmpty ? 0 : _log.currentStage / _log.stages.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(_log.status)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_log.currentStage} of ${_log.stages.length} stages completed',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ..._log.stages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stage = entry.value;
                    return _buildTimelineStage(context, index, stage);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photos Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _addPhoto(context),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_log.photos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No photos yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _log.photos.length,
                      itemBuilder: (context, index) {
                        return _buildPhotoThumbnail(context, index);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add notes about your fermentation process...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _saveNotes(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Notes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStatusDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Status'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _markNextStage(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Next Stage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStage(BuildContext context, int index, FermentationStage stage) {
    final isCompleted = index < _log.currentStage;
    final isCurrent = index == _log.currentStage;
    final scheduled = _log.startAt.add(Duration(days: stage.day));
    final isOverdue = !isCompleted && scheduled.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted 
                    ? Colors.green 
                    : isCurrent 
                      ? Colors.blue 
                      : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted 
                    ? Icons.check 
                    : isCurrent 
                      ? Icons.play_arrow 
                      : Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (index < _log.stages.length - 1)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Stage content
          Expanded(
            child: Card(
              elevation: isCurrent ? 4 : 1,
              color: isCurrent ? Colors.blue[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stage.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.green[800] : null,
                            ),
                          ),
                        ),
                        if (isOverdue && !isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.action,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${_formatDateTime(scheduled)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent && !isCompleted) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _markStageCompleted(context, index),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Done'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(BuildContext context, int index) {
    final photoUrl = _log.photos[index];
    return GestureDetector(
      onTap: () => _showPhotoDialog(context, photoUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                photoUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removePhoto(context, photoUrl),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(FermentationStatus status) {
    switch (status) {
      case FermentationStatus.active:
        return Colors.blue;
      case FermentationStatus.done:
        return Colors.green;
      case FermentationStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addPhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final repo = context.read<FermentationRepo>();
        final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
        await repo.addPhotosToFermentationLog(_log.id, [File(image.path)], uid);
        
        // Refresh the log
        final updatedLog = await repo.getFermentationLog(_log.id);
        if (updatedLog != null) {
          setState(() => _log = updatedLog);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding photo: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto(BuildContext context, String photoUrl) async {
    try {
      final repo = context.read<FermentationRepo>();
      await repo.removePhotoFromFermentationLog(_log.id, photoUrl);
      
      // Refresh the log
      final updatedLog = await repo.getFermentationLog(_log.id);
      if (updatedLog != null) {
        setState(() => _log = updatedLog);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing photo: $e')),
        );
      }
    }
  }

  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Photo'),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _removePhoto(context, photoUrl);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            Expanded(
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Failed to load image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotes(BuildContext context) async {
    try {
      await context.read<FermentationRepo>().updateFermentationNotes(_log.id, _notes.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e')),
        );
      }
    }
  }

  Future<void> _markStageCompleted(BuildContext context, int stageIndex) async {
    try {
      await context.read<FermentationRepo>().markStageCompleted(
        logId: _log.id,
        completedStageIndex: stageIndex,
      );
      
      // Refresh the log
      final repo = context.read<FermentationRepo>();
      final updatedLog = await repo.getFermentationLog(_log.id);
      if (updatedLog != null) {
        setState(() => _log = updatedLog);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stage marked as completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking stage: $e')),
        );
      }
    }
  }

  Future<void> _markNextStage(BuildContext context) async {
    if (_log.currentStage < _log.stages.length) {
      await _markStageCompleted(context, _log.currentStage);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All stages completed!')),
        );
      }
    }
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    final newStatus = await showDialog<FermentationStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FermentationStatus.values.map((status) {
            return ListTile(
              title: Text(status.name.toUpperCase()),
              leading: Radio<FermentationStatus>(
                value: status,
                groupValue: _log.status,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != _log.status) {
      try {
        await context.read<FermentationRepo>().updateFermentationStatus(_log.id, newStatus);
        setState(() => _log = _log.copyWith(status: newStatus));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e')),
          );
        }
      }
    }
  }
}