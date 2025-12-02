import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Management Section
          _buildSectionHeader('User Management', Icons.people_outline),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.how_to_reg_outlined,
                title: 'User Approval Policies',
                subtitle: 'Configure automatic approval and verification',
                onTap: () {
                  _showComingSoonDialog(context, 'User Approval Policies');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.verified_user_outlined,
                title: 'Verification Requirements',
                subtitle: 'Set requirements for user verification',
                onTap: () {
                  _showComingSoonDialog(context, 'Verification Requirements');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.block_outlined,
                title: 'Ban & Suspension Rules',
                subtitle: 'Configure violation thresholds and penalties',
                onTap: () {
                  _showComingSoonDialog(context, 'Ban & Suspension Rules');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content Moderation Section
          _buildSectionHeader('Content Moderation', Icons.gavel_outlined),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.auto_fix_high_outlined,
                title: 'Auto-Moderation Rules',
                subtitle: 'Configure automatic content filtering',
                onTap: () {
                  _showComingSoonDialog(context, 'Auto-Moderation Rules');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.flag_outlined,
                title: 'Flagging Thresholds',
                subtitle: 'Set thresholds for content flagging',
                onTap: () {
                  _showComingSoonDialog(context, 'Flagging Thresholds');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.filter_list_outlined,
                title: 'Content Filters',
                subtitle: 'Manage keyword filters and blocked terms',
                onTap: () {
                  _showComingSoonDialog(context, 'Content Filters');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // System Configuration Section
          _buildSectionHeader('System Configuration', Icons.settings_outlined),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.timer_outlined,
                title: 'Session Timeout',
                subtitle: 'Configure admin session duration',
                onTap: () {
                  _showComingSoonDialog(context, 'Session Timeout');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.storage_outlined,
                title: 'Data Retention',
                subtitle: 'Configure data backup and retention policies',
                onTap: () {
                  _showComingSoonDialog(context, 'Data Retention');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.cloud_upload_outlined,
                title: 'Backup Settings',
                subtitle: 'Configure automatic backup schedules',
                onTap: () {
                  _showComingSoonDialog(context, 'Backup Settings');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Settings Section
          _buildSectionHeader('Security', Icons.security_outlined),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.lock_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Enforce 2FA for admin accounts',
                onTap: () {
                  _showComingSoonDialog(context, 'Two-Factor Authentication');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.password_outlined,
                title: 'Password Policies',
                subtitle: 'Configure password requirements',
                onTap: () {
                  _showComingSoonDialog(context, 'Password Policies');
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                icon: Icons.history_outlined,
                title: 'Access Logs',
                subtitle: 'View admin access history and logs',
                onTap: () {
                  _showComingSoonDialog(context, 'Access Logs');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('Information', Icons.info_outline),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App information and developers',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
            ],
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

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: NatureColors.primaryGreen),
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
      trailing: const Icon(Icons.chevron_right, color: NatureColors.mediumGray),
      onTap: onTap,
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: NatureColors.infoBlue),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature configuration will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


