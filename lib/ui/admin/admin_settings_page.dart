import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.policy_outlined),
            title: Text('Moderation Policies'),
            subtitle: Text('Configure content rules and thresholds'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Security'),
            subtitle: Text('2FA, session timeouts, access logs'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Data Management'),
            subtitle: Text('Backups and retention'),
          ),
        ],
      ),
    );
  }
}


