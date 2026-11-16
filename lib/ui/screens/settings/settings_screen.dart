import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/settings_controller.dart';

/// Screen allowing the user to configure app appearance (Theme)
/// and language (Locale).
class SettingsScreen extends StatelessWidget {
  final SettingsController? controller;

  const SettingsScreen({
    super.key,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final settings = controller ?? SettingsController.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.desktopMaxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                children: [
                  // Appearance Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.settingsAppearance,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RadioGroup<ThemeMode>(
                            groupValue: settings.themeMode,
                            onChanged: (mode) {
                              if (mode != null) {
                                settings.updateThemeMode(mode);
                              }
                            },
                            child: const Column(
                              children: [
                                _ThemeRadioTile(
                                  mode: ThemeMode.light,
                                ),
                                _ThemeRadioTile(
                                  mode: ThemeMode.dark,
                                ),
                                _ThemeRadioTile(
                                  mode: ThemeMode.system,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Language Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.settingsLanguage,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RadioGroup<String>(
                            groupValue: settings.locale.languageCode,
                            onChanged: (code) {
                              if (code != null) {
                                settings.updateLocale(Locale(code));
                              }
                            },
                            child: const Column(
                              children: [
                                _LanguageRadioTile(code: 'vi'),
                                _LanguageRadioTile(code: 'en'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeRadioTile extends StatelessWidget {
  final ThemeMode mode;

  const _ThemeRadioTile({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label;
    switch (mode) {
      case ThemeMode.light:
        label = l10n.settingsThemeLight;
        break;
      case ThemeMode.dark:
        label = l10n.settingsThemeDark;
        break;
      case ThemeMode.system:
        label = l10n.settingsThemeSystem;
        break;
    }

    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: mode,
    );
  }
}

class _LanguageRadioTile extends StatelessWidget {
  final String code;

  const _LanguageRadioTile({required this.code});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = code == 'vi' ? l10n.settingsLanguageVi : l10n.settingsLanguageEn;

    return RadioListTile<String>(
      title: Text(label),
      value: code,
    );
  }
}
