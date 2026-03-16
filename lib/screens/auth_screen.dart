import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'language_selection_screen.dart';
import '../services/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    setState(() => _isLoading = true);
    final error = _isLogin
        ? await appState.loginUser(
            identifier: _identifierCtrl.text,
            password: _passwordCtrl.text,
          )
        : await appState.registerUser(
            identifier: _identifierCtrl.text,
            password: _passwordCtrl.text,
          );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(appState.tr('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change language',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              TextField(
                controller: _identifierCtrl,
                decoration: InputDecoration(
                  labelText: appState.tr('email_or_phone'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appState.tr('password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(_isLogin ? appState.tr('login') : appState.tr('register')),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? '${appState.tr('register')} instead'
                      : '${appState.tr('login')} instead',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
