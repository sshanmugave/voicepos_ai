import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final name = _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) return;

    await appState.addFeedback(customerName: name, message: message);
    if (!mounted) return;
    _messageCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & Improvements')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What should we improve?',
                hintText: 'Tell us your suggestions',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: const Text('Submit Feedback'),
            ),
            const SizedBox(height: 20),
            Text(
              'Recent Feedback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (appState.feedbackEntries.isEmpty)
              const Card(child: ListTile(title: Text('No feedback yet')))
            else
              ...appState.feedbackEntries.take(20).map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.customerName),
                        subtitle: Text(entry.message),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
