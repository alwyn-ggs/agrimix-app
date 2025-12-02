import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../providers/settings_provider.dart';


class AdminNotificationSettingsPage extends StatefulWidget {
  const AdminNotificationSettingsPage({super.key});

  @override
  State<AdminNotificationSettingsPage> createState() => _AdminNotificationSettingsPageState();
}

class _AdminNotificationSettingsPageState extends State<AdminNotificationSettingsPage> {
  // Email Notifications
  bool _emailUserReports = true;
  bool _emailNewRegistrations = true;
  bool _emailSystemAlerts = true;
  bool _emailContentFlags = true;
  bool _emailDailyDigest = false;

  // Push Notifications
  bool _pushUserReports = true;
  bool _pushNewRegistrations = false;
  bool _pushSystemAlerts = true;
  bool _pushContentFlags = true;

  // Notification Frequency
  String _notificationFrequency = 'instant'; // instant, hourly, daily

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<SettingsProvider>();
    await provider.loadAdminNotificationSettings();
    
    setState(() {
      _emailUserReports = provider.emailUserReports;
      _emailNewRegistrations = provider.emailNewRegistrations;
      _emailSystemAlerts = provider.emailSystemAlerts;
      _emailContentFlags = provider.emailContentFlags;
      _emailDailyDigest = provider.emailDailyDigest;
      
      _pushUserReports = provider.pushUserReports;
      _pushNewRegistrations = provider.pushNewRegistrations;
      _pushSystemAlerts = provider.pushSystemAlerts;
      _pushContentFlags = provider.pushContentFlags;
      
      _notificationFrequency = provider.notificationFrequency;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final provider = context.read<SettingsProvider>();
    
    await provider.saveAdminNotificationSettings(
      emailUserReports: _emailUserReports,
      emailNewRegistrations: _emailNewRegistrations,
      emailSystemAlerts: _emailSystemAlerts,
      emailContentFlags: _emailContentFlags,
      emailDailyDigest: _emailDailyDigest,
      pushUserReports: _pushUserReports,
      pushNewRegistrations: _pushNewRegistrations,
      pushSystemAlerts: _pushSystemAlerts,
      pushContentFlags: _pushContentFlags,
      notificationFrequency: _notificationFrequency,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved'),
          backgroundColor: NatureColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _emailUserReports = true;
      _emailNewRegistrations = true;
      _emailSystemAlerts = true;
      _emailContentFlags = true;
      _emailDailyDigest = false;
      
      _pushUserReports = true;
      _pushNewRegistrations = false;
      _pushSystemAlerts = true;
      _pushContentFlags = true;
      
      _notificationFrequency = 'instant';
    });
    
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NatureColors.natureBackground,
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: NatureColors.primaryGreen,
          foregroundColor: NatureColors.pureWhite,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh, color: NatureColors.pureWhite),
            label: const Text('Reset', style: TextStyle(color: NatureColors.pureWhite)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Email Notifications Section
          _buildSectionHeader('Email Notifications', Icons.email_outlined),
          const SizedBox(height: 8),
          _buildNotificationCard(
            children: [
              _buildSwitchTile(
                'User Reports',
                'Receive emails when users report content',
                _emailUserReports,
                (value) => setState(() => _emailUserReports = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'New Registrations',
                'Receive emails for new user registrations',
                _emailNewRegistrations,
                (value) => setState(() => _emailNewRegistrations = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'System Alerts',
                'Receive emails for system alerts and errors',
                _emailSystemAlerts,
                (value) => setState(() => _emailSystemAlerts = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'Content Flags',
                'Receive emails when content is flagged',
                _emailContentFlags,
                (value) => setState(() => _emailContentFlags = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'Daily Digest',
                'Receive a daily summary of all notifications',
                _emailDailyDigest,
                (value) => setState(() => _emailDailyDigest = value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Push Notifications Section
          _buildSectionHeader('Push Notifications', Icons.notifications_outlined),
          const SizedBox(height: 8),
          _buildNotificationCard(
            children: [
              _buildSwitchTile(
                'User Reports',
                'Receive push notifications for user reports',
                _pushUserReports,
                (value) => setState(() => _pushUserReports = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'New Registrations',
                'Receive push notifications for new users',
                _pushNewRegistrations,
                (value) => setState(() => _pushNewRegistrations = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'System Alerts',
                'Receive push notifications for system alerts',
                _pushSystemAlerts,
                (value) => setState(() => _pushSystemAlerts = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'Content Flags',
                'Receive push notifications for flagged content',
                _pushContentFlags,
                (value) => setState(() => _pushContentFlags = value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notification Frequency Section
          _buildSectionHeader('Notification Frequency', Icons.schedule_outlined),
          const SizedBox(height: 8),
          _buildNotificationCard(
            children: [
              RadioListTile<String>(
                title: const Text('Instant'),
                subtitle: const Text('Receive notifications immediately'),
                value: 'instant',
                groupValue: _notificationFrequency,
                activeColor: NatureColors.primaryGreen,
                onChanged: (value) {
                  setState(() => _notificationFrequency = value!);
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Hourly'),
                subtitle: const Text('Receive notifications every hour'),
                value: 'hourly',
                groupValue: _notificationFrequency,
                activeColor: NatureColors.primaryGreen,
                onChanged: (value) {
                  setState(() => _notificationFrequency = value!);
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Daily'),
                subtitle: const Text('Receive notifications once per day'),
                value: 'daily',
                groupValue: _notificationFrequency,
                activeColor: NatureColors.primaryGreen,
                onChanged: (value) {
                  setState(() => _notificationFrequency = value!);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Save Button
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: NatureColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: NatureColors.primaryGreen, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: NatureColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: NatureColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: NatureColors.mediumGray,
        ),
      ),
      value: value,
      activeColor: NatureColors.primaryGreen,
      onChanged: onChanged,
    );
  }
}
