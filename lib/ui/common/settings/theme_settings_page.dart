import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../theme/theme.dart';
import '../../../l10n/app_localizations.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: Text(t.t('theme')),
      ),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: Text(t.t('light')),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) {
              if (v != null) context.read<SettingsProvider>().setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(t.t('dark')),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) {
              if (v != null) context.read<SettingsProvider>().setThemeMode(v);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Text(t.t('use_system_theme')),
            value: settings.themeMode == ThemeMode.system,
            onChanged: (useSystem) {
              context.read<SettingsProvider>().setThemeMode(
                    useSystem ? ThemeMode.system : ThemeMode.light,
                  );
            },
          ),
        ],
      ),
    );
  }
}


