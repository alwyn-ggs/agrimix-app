import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../repositories/fermentation_repo.dart';
import '../../repositories/recipes_repo.dart';
import '../../repositories/users_repo.dart';
import '../../models/fermentation_log.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../models/stage_completion.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/stage_management_service.dart';
import '../../services/storage_service.dart';


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
  final Map<int, Timer?> _notesDebounceTimers = {};
  final Map<int, TextEditingController> _stageNotesControllers = {};
  int _refreshKey = 0; // Key to force FutureBuilder refresh

  @override
  void initState() {
    super.initState();
    _log = widget.log;
  }

  @override
  void dispose() {
    for (final timer in _notesDebounceTimers.values) {
      timer?.cancel();
    }
    _notesDebounceTimers.clear();
    for (final controller in _stageNotesControllers.values) {
      controller.dispose();
    }
    _stageNotesControllers.clear();
    super.dispose();
  }

  TextEditingController _getStageNotesController(int stageIndex, String initialValue) {
    if (!_stageNotesControllers.containsKey(stageIndex)) {
      _stageNotesControllers[stageIndex] = TextEditingController(text: initialValue);
    } else {
      // Update if value changed externally
      final controller = _stageNotesControllers[stageIndex]!;
      if (controller.text != initialValue) {
        controller.text = initialValue;
      }
    }
    return _stageNotesControllers[stageIndex]!;
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
                    FutureBuilder<Recipe?>(
                      future: context.read<RecipesRepo>().getRecipe(_log.recipeId!),
                      builder: (context, recipeSnap) {
                        if (recipeSnap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final recipe = recipeSnap.data;
                        if (recipe == null) {
                          return const Row(
                            children: [
                              Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Linked to recipe: unavailable')
                            ],
                          );
                        }
                        return FutureBuilder<AppUser?>(
                          future: context.read<UsersRepo>().getUser(recipe.ownerUid),
                          builder: (context, ownerSnap) {
                            final data = ownerSnap.data;
                            final ownerName = (data != null && data.name.trim().isNotEmpty)
                                ? data.name
                                : 'Unknown';
                            return Row(
                              children: [
                                const Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Linked to recipe: ${recipe.name} • by $ownerName',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
    
    // Calculate current day of fermentation
    final now = DateTime.now();
    final daysSinceStart = now.difference(_log.startAt).inDays;
    final isTodayStage = daysSinceStart == stage.day;
    
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
              child: InkWell(
                onTap: () => _showStageDetails(context, index, stage),
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
                    // Show action only when the scheduled time has arrived (after notification time)
                    if (isCurrent && !isCompleted && !scheduled.isAfter(DateTime.now())) ...[
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
                      // Show attach options only when current day matches stage day
                      if (isTodayStage) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        FutureBuilder<StageCompletion?>(
                          key: ValueKey('stage_${index}_$_refreshKey'), // Force refresh on key change
                          future: StageManagementService().getStageCompletionByIndex(
                            fermentationLogId: _log.id,
                            stageIndex: index,
                          ),
                          builder: (context, snapshot) {
                            final completion = snapshot.data;
                            final photos = completion?.photos ?? const <String>[];
                            final initialNotes = completion?.notes ?? '';
                            
                            return StatefulBuilder(
                              builder: (context, setLocalState) {
                                final notesController = _getStageNotesController(index, initialNotes);
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Photos section
                                    Row(
                                      children: [
                                        const Icon(Icons.photo_library, size: 18, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Photos',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () async {
                                            await _addStagePhoto(context, index, stage);
                                            setLocalState(() {}); // Refresh to show new photo
                                          },
                                          icon: const Icon(Icons.add_a_photo, size: 16),
                                          label: const Text('Add'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (photos.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 60,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: photos.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                                          itemBuilder: (context, i) {
                                            return GestureDetector(
                                              onTap: () => _showPhotoDialog(context, photos[i]),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  photos[i],
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.broken_image, size: 24),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Notes section
                                    const Row(
                                      children: [
                                        Icon(Icons.note, size: 18, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                          'Notes',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: notesController,
                                      minLines: 2,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Add notes (optional)...',
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        // Save notes as user types (debounced)
                                        _saveStageNotesDebounced(context, index, value);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStageDetails(BuildContext context, int index, FermentationStage stage) async {
    final service = StageManagementService();
    final storage = context.read<StorageService>();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    final completion = await service.getStageCompletionByIndex(
      fermentationLogId: _log.id,
      stageIndex: index,
    );

    final notesController = TextEditingController(text: completion?.notes ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final photos = completion?.photos ?? const <String>[];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stage Details • Day ${stage.day} • ${stage.label}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(stage.action, style: TextStyle(color: Colors.grey[700])),
                  if (completion?.duration != null) ...[
                    const SizedBox(height: 8),
                    Text('Duration: ${completion!.duration!.inHours}h ${completion.duration!.inMinutes % 60}m',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: completion == null ? null : () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.camera);
                          if (picked != null) {
                            final url = await storage.uploadFile(
                              file: File(picked.path),
                              userId: uid,
                              folder: 'fermentation_stage',
                            );
                            await service.addPhotosToStage(stageId: completion.id, photoUrls: [url]);
                            // Refresh modal by closing and reopening with updated data
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showStageDetails(context, index, stage);
                            }
                          }
                        },
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (photos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No photos yet', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final url = photos[i];
                          return GestureDetector(
                            onTap: () => _showPhotoDialog(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add notes for this stage...'
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: completion == null ? null : () async {
                        await service.updateStageNotes(stageId: completion.id, notes: notesController.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage notes saved.')));
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Notes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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


  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Constrain dialog size to avoid overflow on small screens
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            minHeight: 200,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Photo'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Failed to load image'),
                      ),
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

  Future<void> _addStagePhoto(BuildContext context, int stageIndex, FermentationStage stage) async {
    try {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add photos')),
          );
        }
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );
      
      if (picked == null) return;

      final service = StageManagementService();
      final storage = context.read<StorageService>();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Uploading photo...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Ensure stage completion exists
      final completion = await service.ensureStageCompletion(
        fermentationLogId: _log.id,
        stageIndex: stageIndex,
        stage: stage,
        userId: uid,
      );

      // Upload photo
      final url = await storage.uploadFile(
        file: File(picked.path),
        userId: uid,
        folder: 'fermentation_stage',
      );

      // Add photo to stage
      await service.addPhotosToStage(stageId: completion.id, photoUrls: [url]);

      // Refresh UI
      if (mounted) {
        setState(() {
          _refreshKey++; // Force FutureBuilder to refresh
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added successfully!')),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding photo: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Log the error for debugging
      print('Error adding stage photo: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _saveStageNotesDebounced(BuildContext context, int stageIndex, String notes) {
    // Cancel existing timer for this stage
    _notesDebounceTimers[stageIndex]?.cancel();

    // Create new timer
    _notesDebounceTimers[stageIndex] = Timer(const Duration(seconds: 2), () async {
      await _saveStageNotes(context, stageIndex, notes);
      _notesDebounceTimers.remove(stageIndex);
    });
  }

  Future<void> _saveStageNotes(BuildContext context, int stageIndex, String notes) async {
    try {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to save notes')),
          );
        }
        return;
      }

      final service = StageManagementService();
      final stage = _log.stages[stageIndex];

      // Ensure stage completion exists
      final completion = await service.ensureStageCompletion(
        fermentationLogId: _log.id,
        stageIndex: stageIndex,
        stage: stage,
        userId: uid,
      );

      // Update notes
      await service.updateStageNotes(
        stageId: completion.id,
        notes: notes.trim().isEmpty ? null : notes.trim(),
      );

      // Refresh UI
      if (mounted) {
        setState(() {
          _refreshKey++; // Force FutureBuilder to refresh
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notes: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Log the error for debugging
      print('Error saving stage notes: $e');
      print('Stack trace: $stackTrace');
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