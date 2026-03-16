import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class AIAutomationScreen extends StatelessWidget {
  const AIAutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final suggestions = appState.aiReorderSuggestions;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights & Automation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Business AI Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...appState.businessTypeAiInsights.map(
              (insight) => Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(insight),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Automatic Stock Reorder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (suggestions.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('No low stock alerts right now.'),
                ),
              )
            else
              ...suggestions.map(
                (s) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.productName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(s.message),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: s.supplier == null
                                  ? null
                                  : () => appState.confirmAIReorder(s),
                              child: const Text('Confirm Order'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
