import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';
import '../services/app_state.dart';

class SalonCustomersScreen extends StatelessWidget {
  const SalonCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Salon Customer Records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
      body: appState.customers.isEmpty
          ? const Center(child: Text('No customers yet. Add your first customer.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: appState.customers.length,
              itemBuilder: (context, index) {
                final customer = appState.customers[index];
                final history = appState.salonVisitsForCustomer(customer.id);
                return Card(
                  child: ListTile(
                    title: Text(customer.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.phone.isEmpty ? 'No phone' : customer.phone),
                        if (history.isNotEmpty)
                          Text(
                            'Last visit: ${history.first.service} • ${_date(history.first.createdAt)}',
                          )
                        else
                          const Text('No visit history yet'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_task),
                      tooltip: 'Add visit',
                      onPressed: () => _showAddVisitDialog(context, customer),
                    ),
                    onTap: () => _showVisitHistory(context, customer),
                  ),
                );
              },
            ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await context.read<AppState>().addCustomer(
                      Customer(
                        id: 0,
                        name: name,
                        phone: phoneCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddVisitDialog(BuildContext context, Customer customer) async {
    final serviceCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add Visit • ${customer.name}'),
          content: TextField(
            controller: serviceCtrl,
            decoration: const InputDecoration(
              labelText: 'Service',
              hintText: 'Haircut, Shave, Facial',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final service = serviceCtrl.text.trim();
                if (service.isEmpty) return;
                await context.read<AppState>().addSalonVisit(
                      customerId: customer.id,
                      customerName: customer.name,
                      service: service,
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showVisitHistory(BuildContext context, Customer customer) async {
    final visits = context.read<AppState>().salonVisitsForCustomer(customer.id);
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${customer.name} - Visit History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (visits.isEmpty)
                  const Text('No visits recorded yet.')
                else
                  ...visits.take(20).map(
                        (visit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(visit.service)),
                              Text(_date(visit.createdAt)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
