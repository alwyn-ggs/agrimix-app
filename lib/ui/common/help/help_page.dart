import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Find quick answers and ways to contact us.',
            style: TextStyle(color: NatureColors.darkGray),
          ),
          const SizedBox(height: 12),

          const _FaqSection(
            title: 'Getting Started',
            items: [
              _FaqItem(
                q: 'How do I create an account?',
                a: 'Tap Create Account on the login screen and fill in your details. You will need a valid email address. Optional: membership ID if provided by your co-op.',
              ),
              _FaqItem(
                q: 'I forgot my password. What should I do?',
                a: 'Use the Forgot Password link on the login screen to receive a reset email.',
              ),
            ],
          ),
          const _FaqSection(
            title: 'Fermentation Logs',
            items: [
              _FaqItem(
                q: 'How do I start a new fermentation log?',
                a: 'Go to Ferment tab and tap New Log. Add stage data, photos, and notes as you progress.',
              ),
              _FaqItem(
                q: 'Can I edit a completed stage?',
                a: 'Yes. Open the log details, select the stage, and tap Edit to update values or notes.',
              ),
            ],
          ),
          const _FaqSection(
            title: 'Recipes & Community',
            items: [
              _FaqItem(
                q: 'Where can I find recommended recipes?',
                a: 'Open the Recipes tab to browse, filter, and view detailed instructions and nutrient profiles.',
              ),
              _FaqItem(
                q: 'How do I post to the community?',
                a: 'Go to Community tab and tap New Post. Follow community guidelines and keep it respectful.',
              ),
            ],
          ),
          const _FaqSection(
            title: 'Notifications',
            items: [
              _FaqItem(
                q: 'I am not receiving notifications.',
                a: 'Ensure notifications are enabled in your device settings and within the app notification preferences. Also check your internet connection.',
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          const Text('Quick Links', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _open(context, 'mailto:agrimix6@gmail.com?subject=AgriMix%20Support'),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email Support'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/terms'),
                icon: const Icon(Icons.article_outlined),
                label: const Text('Terms of Service'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/privacy'),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Privacy Policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final String title;
  final List<_FaqItem> items;
  const _FaqSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...items.map((i) => _FaqTile(item: i)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: NatureColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: NatureColors.lightGreen.withAlpha((0.3 * 255).round())),
      ),
      child: ExpansionTile(
        title: Text(item.q, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(item.a),
          ),
        ],
      ),
    );
  }
}

Future<void> _open(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}


