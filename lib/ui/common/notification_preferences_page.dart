import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_preferences.dart';
import '../../services/notification_preferences_service.dart' show NotificationPreferencesService;
import '../../services/messaging_service.dart';
import '../../theme/theme.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  final MessagingService _messagingService = MessagingService();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('User not authenticated');
      return;
    }

    try {
      final prefs = await _preferencesService.getUserPreferences(currentUser.uid);
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load preferences: ${e.toString()}');
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _preferencesService.savePreferences(_preferences!);
      if (success) {
        _showSuccessSnackBar('Preferences saved successfully');
        // After saving, sync topics
        await _syncTopicsForCurrentPrefs();
      } else {
        _showErrorSnackBar('Failed to save preferences');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save preferences');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _ensurePermissionAndRegisterTokenIfEnabled({required bool enabled}) async {
    if (!enabled) return;
    final granted = await _messagingService.requestPermission();
    if (!granted) {
      _showErrorSnackBar('Notification permission denied');
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final token = await _messagingService.getToken();
    if (token != null) {
      await _messagingService.saveTokenToUser(user.uid, token);
    }
  }

  Future<void> _syncTopicsForCurrentPrefs() async {
    final prefs = _preferences;
    final user = context.read<AuthProvider>().currentUser;
    if (prefs == null || user == null) return;

    // If push channel or global is disabled, unsubscribe from all known types
    final pushEnabled = prefs.channels['push'] ?? false;
    if (!prefs.enabled || !pushEnabled) {
      for (final type in prefs.notificationTypes.keys) {
        await _messagingService.unsubscribeFromTopic(type);
      }
      return;
    }

    // Subscribe/unsubscribe based on per-type toggle
    for (final entry in prefs.notificationTypes.entries) {
      if (entry.value) {
        await _messagingService.subscribeToTopic(entry.key);
      } else {
        await _messagingService.unsubscribeFromTopic(entry.key);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NatureColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load preferences'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPreferences,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainToggle(),
            const SizedBox(height: 24),
            _buildNotificationTypes(),
            const SizedBox(height: 24),
            _buildChannels(),
            const SizedBox(height: 24),
            _buildTimePreferences(),
            const SizedBox(height: 24),
            _buildFrequencyPreferences(),
            const SizedBox(height: 24),
            _buildQuietHours(),
            const SizedBox(height: 24),
            _buildDigestSettings(),
            const SizedBox(height: 24),
            _buildResetButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.notifications, color: NatureColors.primaryGreen, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preferences!.enabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      color: _preferences!.enabled ? NatureColors.primaryGreen : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _preferences!.enabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(enabled: value);
                });
                _ensurePermissionAndRegisterTokenIfEnabled(enabled: value);
              },
              activeColor: NatureColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._preferences!.notificationTypes.entries.map((entry) {
              return _buildToggleTile(
                title: _getNotificationTypeTitle(entry.key),
                subtitle: _getNotificationTypeSubtitle(entry.key),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    final updatedTypes = Map<String, bool>.from(_preferences!.notificationTypes);
                    updatedTypes[entry.key] = value;
                    _preferences = _preferences!.copyWith(notificationTypes: updatedTypes);
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChannels() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Channels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._preferences!.channels.entries.map((entry) {
              return _buildToggleTile(
                title: _getChannelTitle(entry.key),
                subtitle: _getChannelSubtitle(entry.key),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    final updatedChannels = Map<String, bool>.from(_preferences!.channels);
                    updatedChannels[entry.key] = value;
                    _preferences = _preferences!.copyWith(channels: updatedChannels);
                  });
                  if (entry.key == 'push') {
                    _ensurePermissionAndRegisterTokenIfEnabled(enabled: value);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTimeZoneSelector(),
            const SizedBox(height: 16),
            _buildPreferredHours(),
            const SizedBox(height: 16),
            _buildPreferredDays(),
            const SizedBox(height: 16),
            _buildTimeFormat(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeZoneSelector() {
    return ListTile(
      title: const Text('Timezone'),
      subtitle: Text(_preferences!.timePreferences.timezone),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showTimeZoneSelector(),
    );
  }

  Widget _buildPreferredHours() {
    return ExpansionTile(
      title: const Text('Preferred Hours'),
      subtitle: Text('${_preferences!.timePreferences.preferredHours.length} hours selected'),
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(24, (hour) {
            final isSelected = _preferences!.timePreferences.preferredHours.contains(hour);
            return FilterChip(
              label: Text('${hour.toString().padLeft(2, '0')}:00'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final hours = List<int>.from(_preferences!.timePreferences.preferredHours);
                  if (selected) {
                    hours.add(hour);
                  } else {
                    hours.remove(hour);
                  }
                  hours.sort();
                  _preferences = _preferences!.copyWith(
                    timePreferences: _preferences!.timePreferences.copyWith(
                      preferredHours: hours,
                    ),
                  );
                });
              },
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreferredDays() {
    return ExpansionTile(
      title: const Text('Preferred Days'),
      subtitle: Text('${_preferences!.timePreferences.preferredDays.length} days selected'),
      children: [
        Wrap(
          spacing: 8,
          children: const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map((day) {
            final isSelected = _preferences!.timePreferences.preferredDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final days = List<String>.from(_preferences!.timePreferences.preferredDays);
                  if (selected) {
                    days.add(day);
                  } else {
                    days.remove(day);
                  }
                  _preferences = _preferences!.copyWith(
                    timePreferences: _preferences!.timePreferences.copyWith(
                      preferredDays: days,
                    ),
                  );
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeFormat() {
    return ListTile(
      title: const Text('Time Format'),
      subtitle: Text(_preferences!.timePreferences.timeFormat == '12h' ? '12-hour (AM/PM)' : '24-hour'),
      trailing: DropdownButton<String>(
        value: _preferences!.timePreferences.timeFormat,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _preferences = _preferences!.copyWith(
                timePreferences: _preferences!.timePreferences.copyWith(
                  timeFormat: value,
                ),
              );
            });
          }
        },
        items: const [
          DropdownMenuItem(value: '12h', child: Text('12-hour (AM/PM)')),
          DropdownMenuItem(value: '24h', child: Text('24-hour')),
        ],
      ),
    );
  }

  Widget _buildFrequencyPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequency Limits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFrequencySlider(
              title: 'Daily Notifications',
              value: int.tryParse(_preferences!.frequencyPreferences.maxDailyNotifications) ?? 10,
              max: 50,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    frequencyPreferences: _preferences!.frequencyPreferences.copyWith(
                      maxDailyNotifications: value.toString(),
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            _buildFrequencySlider(
              title: 'Weekly Notifications',
              value: int.tryParse(_preferences!.frequencyPreferences.maxWeeklyNotifications) ?? 50,
              max: 200,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    frequencyPreferences: _preferences!.frequencyPreferences.copyWith(
                      maxWeeklyNotifications: value.toString(),
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            _buildToggleTile(
              title: 'Batch Similar Notifications',
              subtitle: 'Group similar notifications together',
              value: _preferences!.frequencyPreferences.batchSimilarNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    frequencyPreferences: _preferences!.frequencyPreferences.copyWith(
                      batchSimilarNotifications: value,
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Adaptive Frequency',
              subtitle: 'Adjust frequency based on your engagement',
              value: _preferences!.frequencyPreferences.adaptiveFrequency,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    frequencyPreferences: _preferences!.frequencyPreferences.copyWith(
                      adaptiveFrequency: value,
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySlider({
    required String title,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text('$value'),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: max.toDouble(),
          divisions: max - 1,
          onChanged: (value) => onChanged(value.round()),
          activeColor: NatureColors.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildQuietHours() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Quiet Hours',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _preferences!.quietHoursEnabled,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences!.copyWith(quietHoursEnabled: value);
                    });
                  },
                  activeColor: NatureColors.primaryGreen,
                ),
              ],
            ),
            if (_preferences!.quietHoursEnabled) ...[
              const SizedBox(height: 16),
              _buildTimePicker(
                title: 'Start Time',
                time: _preferences!.quietHoursStart,
                onTimeChanged: (time) {
                  setState(() {
                    _preferences = _preferences!.copyWith(quietHoursStart: time);
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTimePicker(
                title: 'End Time',
                time: _preferences!.quietHoursEnd,
                onTimeChanged: (time) {
                  setState(() {
                    _preferences = _preferences!.copyWith(quietHoursEnd: time);
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildQuietDays(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String title,
    required DateTime? time,
    required ValueChanged<DateTime> onTimeChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time != null 
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set'),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time != null 
              ? TimeOfDay.fromDateTime(time)
              : const TimeOfDay(hour: 22, minute: 0),
        );
        if (picked != null) {
          final now = DateTime.now();
          final selectedTime = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
          onTimeChanged(selectedTime);
        }
      },
    );
  }

  Widget _buildQuietDays() {
    return ExpansionTile(
      title: const Text('Quiet Days'),
      subtitle: Text('${_preferences!.quietDays.length} days selected'),
      children: [
        Wrap(
          spacing: 8,
          children: const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map((day) {
            final isSelected = _preferences!.quietDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final days = List<String>.from(_preferences!.quietDays);
                  if (selected) {
                    days.add(day);
                  } else {
                    days.remove(day);
                  }
                  _preferences = _preferences!.copyWith(quietDays: days);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDigestSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Digest Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _preferences!.digestEnabled,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences!.copyWith(digestEnabled: value);
                    });
                  },
                  activeColor: NatureColors.primaryGreen,
                ),
              ],
            ),
            if (_preferences!.digestEnabled) ...[
              const SizedBox(height: 16),
              _buildDigestFrequency(),
              const SizedBox(height: 16),
              _buildDigestTime(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigestFrequency() {
    return ListTile(
      title: const Text('Digest Frequency'),
      subtitle: Text(_getDigestFrequencyTitle(_preferences!.digestFrequency)),
      trailing: DropdownButton<String>(
        value: _preferences!.digestFrequency,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _preferences = _preferences!.copyWith(digestFrequency: value);
            });
          }
        },
        items: const [
          DropdownMenuItem(value: 'daily', child: Text('Daily')),
          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
        ],
      ),
    );
  }

  Widget _buildDigestTime() {
    return ListTile(
      title: const Text('Digest Time'),
      subtitle: Text(_preferences!.digestTime),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final timeParts = _preferences!.digestTime.split(':');
        final initialTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        
        if (picked != null) {
          setState(() {
            _preferences = _preferences!.copyWith(
              digestTime: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            );
          });
        }
      },
    );
  }

  Widget _buildResetButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reset all notification preferences to default values',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showResetDialog(),
                child: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: NatureColors.primaryGreen,
      ),
    );
  }

  void _showTimeZoneSelector() {
    // Implementation for timezone selector
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: const Text('Timezone selection will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text('Are you sure you want to reset all notification preferences to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _preferencesService.resetToDefaults(currentUser.uid);
      if (success) {
        await _loadPreferences();
        _showSuccessSnackBar('Preferences reset to defaults');
      } else {
        _showErrorSnackBar('Failed to reset preferences');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reset preferences');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getNotificationTypeTitle(String type) {
    switch (type) {
      case 'announcements':
        return 'Announcements';
      case 'fermentation_reminders':
        return 'Fermentation Reminders';
      case 'community_updates':
        return 'Community Updates';
      case 'moderation_alerts':
        return 'Moderation Alerts';
      case 'system_updates':
        return 'System Updates';
      case 'marketing':
        return 'Marketing';
      default:
        return type;
    }
  }

  String _getNotificationTypeSubtitle(String type) {
    switch (type) {
      case 'announcements':
        return 'Important announcements from administrators';
      case 'fermentation_reminders':
        return 'Reminders for fermentation stages and tasks';
      case 'community_updates':
        return 'Updates from the community and other users';
      case 'moderation_alerts':
        return 'Alerts about content moderation and violations';
      case 'system_updates':
        return 'System maintenance and feature updates';
      case 'marketing':
        return 'Promotional content and offers';
      default:
        return '';
    }
  }

  String _getChannelTitle(String channel) {
    switch (channel) {
      case 'push':
        return 'Push Notifications';
      case 'email':
        return 'Email';
      case 'sms':
        return 'SMS';
      case 'in_app':
        return 'In-App Notifications';
      default:
        return channel;
    }
  }

  String _getChannelSubtitle(String channel) {
    switch (channel) {
      case 'push':
        return 'Notifications on your device';
      case 'email':
        return 'Email notifications';
      case 'sms':
        return 'Text message notifications';
      case 'in_app':
        return 'Notifications within the app';
      default:
        return '';
    }
  }

  String _getDigestFrequencyTitle(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }
}
