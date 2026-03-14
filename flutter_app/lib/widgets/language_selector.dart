import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../core/language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: l10n.selectLanguage,
      onSelected: (Locale locale) {
        languageService.setLocale(locale);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Row(
            children: [
              if (languageService.locale?.languageCode == 'en')
                const Icon(Icons.check, color: Colors.orange),
              if (languageService.locale?.languageCode == 'en')
                const SizedBox(width: 8),
              const Text('🇬🇧 '),
              Text(l10n.english),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('hi'),
          child: Row(
            children: [
              if (languageService.locale?.languageCode == 'hi')
                const Icon(Icons.check, color: Colors.orange),
              if (languageService.locale?.languageCode == 'hi')
                const SizedBox(width: 8),
              const Text('🇮🇳 '),
              Text(l10n.hindi),
            ],
          ),
        ),
        PopupMenuItem(
          value: const Locale('mr'),
          child: Row(
            children: [
              if (languageService.locale?.languageCode == 'mr')
                const Icon(Icons.check, color: Colors.orange),
              if (languageService.locale?.languageCode == 'mr')
                const SizedBox(width: 8),
              const Text('🕉️ '),
              Text(l10n.marathi),
            ],
          ),
        ),
      ],
    );
  }
}
