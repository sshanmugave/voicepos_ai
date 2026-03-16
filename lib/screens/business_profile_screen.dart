import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/business_profile_model.dart';
import '../models/business_type.dart';
import '../services/app_state.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key, this.isInitialSetup = false});

  final bool isInitialSetup;

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  BusinessType _businessType = BusinessType.restaurant;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _shopNameCtrl = TextEditingController(text: profile?.shopName ?? '');
    _ownerNameCtrl = TextEditingController(text: profile?.ownerName ?? '');
    _gstCtrl = TextEditingController(text: profile?.gstNumber ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _addressCtrl = TextEditingController(text: profile?.address ?? '');
    _businessType = profile?.businessType ?? BusinessType.restaurant;
    _logoPath = profile?.logoPath;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _gstCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    if (widget.isInitialSetup && await appState.hasBusinessData()) {
      if (!mounted) return;
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Existing Data Detected'),
            content: const Text(
              'Sample or previous billing data was found. Do you want to clear it and start fresh for this business setup?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep Existing Data'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Clear & Start Fresh'),
              ),
            ],
          );
        },
      );
      if (shouldClear == true) {
        await appState.clearBusinessData();
      }
    }

    final profile = BusinessProfile(
      id: appState.profile?.id ?? 1,
      shopName: _shopNameCtrl.text.trim(),
      businessType: _businessType,
      ownerName: _ownerNameCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoPath: _logoPath,
    );

    await appState.saveBusinessProfile(profile);

    if (mounted) {
      if (widget.isInitialSetup) {
        // Navigate to home, clear back stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Set Up Your Shop' : 'Business Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _logoPath != null ? FileImage(File(_logoPath!)) : null,
                      child: _logoPath == null
                          ? const Icon(Icons.add_a_photo, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Tap to add logo')),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _shopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name *',
                    hintText: 'e.g. Arun Tea Stall',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Business Type',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BusinessType.values
                      .map(
                        (type) => ChoiceChip(
                          label: Text(type.label),
                          selected: _businessType == type,
                          onSelected: (_) => setState(() => _businessType = type),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gstCtrl,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    hintText: '15 character GST number',
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length != 15) return 'GSTIN must be 15 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length != 10) return 'Enter 10 digit phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(widget.isInitialSetup ? 'Continue' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
