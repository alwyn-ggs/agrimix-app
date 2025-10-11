import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../theme/theme.dart';
import '../../../l10n/app_localizations.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: Text(t.t('language')),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text(t.t('english')),
            value: 'en',
            groupValue: settings.locale.languageCode,
            onChanged: (code) {
              if (code != null) context.read<SettingsProvider>().setLocale(Locale(code));
            },
          ),
          RadioListTile<String>(
            title: Text(t.t('tagalog')),
            value: 'tl',
            groupValue: settings.locale.languageCode,
            onChanged: (code) {
              if (code != null) context.read<SettingsProvider>().setLocale(Locale(code));
            },
          ),
        ],
      ),
    );
  }
}


