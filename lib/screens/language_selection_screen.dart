import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final options = const [
      ('en', 'English'),
      ('ta', 'Tamil'),
      ('hi', 'Hindi'),
      ('te', 'Telugu'),
      ('ml', 'Malayalam'),
      ('kn', 'Kannada'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appState.tr('select_language'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: appState.selectedLanguageCode,
                onChanged: (value) {
                  if (value != null) {
                    appState.setLanguage(value);
                  }
                },
                child: Column(
                  children: options
                      .map(
                        (entry) => Card(
                          child: ListTile(
                            leading: Radio<String>(value: entry.$1),
                            title: Text(entry.$2),
                            onTap: () => appState.setLanguage(entry.$1),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await appState.setLanguage(appState.selectedLanguageCode);
                  },
                  child: Text(appState.tr('continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
