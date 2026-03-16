import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business_type.dart';
import '../services/app_state.dart';
import 'ai_automation_screen.dart';
import 'billing_screen.dart';
import 'b2b_marketplace_screen.dart';
import 'business_profile_screen.dart';
import 'credit_collection_screen.dart';
import 'dashboard_screen.dart';
import 'data_export_screen.dart';
import 'day_end_report_screen.dart';
import 'expense_tracker_screen.dart';
import 'feedback_screen.dart';
import 'inventory_screen.dart';
import 'notifications_screen.dart';
import 'sales_analytics_screen.dart';
import 'sales_history_screen.dart';
import 'salon_customers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    BillingScreen(),
    InventoryScreen(),
    DashboardScreen(),
    _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(appState.shopName.isEmpty ? 'VoicePOS AI' : appState.shopName),
        actions: [
          IconButton(
            onPressed: () => appState.toggleDarkMode(),
            icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) => setState(() => _currentIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale_rounded), label: 'Billing'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Business Section ──
          _buildSectionHeader(context, 'Business'),
          _buildMenuItem(
            context,
            icon: Icons.store,
            title: 'Business Profile',
            subtitle: appState.shopName,
            color: theme.colorScheme.primary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            ),
          ),
          
          // ── Reports Section ──
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Reports & Analytics'),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long,
            title: 'Sales History',
            subtitle: 'View all past orders',
            color: Colors.blue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.summarize,
            title: 'Day-End Report',
            subtitle: 'Daily summary & insights',
            color: Colors.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DayEndReportScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart,
            title: 'Sales Analytics',
            subtitle: 'Daily chart, top items, smart insights',
            color: Colors.green,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalesAnalyticsScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.file_download,
            title: 'Export Data',
            subtitle: 'Export to PDF/CSV',
            color: Colors.indigo,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataExportScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: _businessTypeIcon(appState.businessType),
            title: 'AI Automation',
            subtitle: 'Predictions, stock alerts, auto reorder',
            color: Colors.deepPurple,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AIAutomationScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.storefront_outlined,
            title: 'B2B Marketplace',
            subtitle: 'Buy raw materials from suppliers',
            color: Colors.brown,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const B2BMarketplaceScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: '${appState.notifications.where((n) => !n.isRead).length} unread alerts',
            color: Colors.redAccent,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.rate_review_outlined,
            title: 'Feedback',
            subtitle: 'Collect customer suggestions',
            color: Colors.cyan,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ),
          ),

          // ── Money Section ──
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Money Management'),
          _buildMenuItem(
            context,
            icon: Icons.money_off,
            title: 'Expenses',
            subtitle: 'Track business expenses',
            color: Colors.red,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Credit Collection',
            subtitle: '₹${appState.totalCreditOutstanding.toStringAsFixed(0)} outstanding',
            color: Colors.orange,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreditCollectionScreen()),
            ),
          ),
          
          // ── People Section ──
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'People'),
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Customers',
            subtitle: '${appState.customers.length} customers',
            color: Colors.purple,
            onTap: () => _showCustomerList(context),
          ),
          if (appState.isSalonBusiness)
            _buildMenuItem(
              context,
              icon: Icons.content_cut,
              title: 'Salon Customer Records',
              subtitle: 'Track services and last visits',
              color: Colors.deepOrange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalonCustomersScreen()),
              ),
            ),
          
          // ── Settings Section ──
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Settings'),
          SwitchListTile(
            secondary: Icon(
              appState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.amber,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(appState.isDarkMode ? 'Currently on' : 'Currently off'),
            value: appState.isDarkMode,
            onChanged: (_) => appState.toggleDarkMode(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.rocket_launch_outlined),
            title: const Text('Demo Mode'),
            subtitle: Text(appState.isDemoMode
                ? 'Mock AI dataset active'
                : 'Enable for hackathon simulation'),
            value: appState.isDemoMode,
            onChanged: (_) => appState.toggleDemoMode(),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.receipt_long,
              color: appState.gstEnabled ? Colors.green : Colors.grey,
            ),
            title: const Text('GST on Bills'),
            subtitle: Text(appState.gstEnabled
                ? 'GST included in billing'
                : 'GST excluded from bills'),
            value: appState.gstEnabled,
            onChanged: (_) => appState.toggleGst(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            subtitle: const Text('Clear session and return to login'),
            onTap: () async {
              await context.read<AppState>().logout();
            },
          ),
        ],
      ),
    );
  }

  IconData _businessTypeIcon(BusinessType type) {
    switch (type) {
      case BusinessType.teaShop:
        return Icons.local_cafe;
      case BusinessType.restaurant:
        return Icons.restaurant;
      case BusinessType.salon:
        return Icons.content_cut;
      case BusinessType.juiceShop:
        return Icons.local_drink;
      case BusinessType.bakery:
        return Icons.bakery_dining;
      case BusinessType.streetVendor:
        return Icons.store;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showCustomerList(BuildContext context) {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Customers',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: appState.customers.isEmpty
                  ? const Center(child: Text('No customers yet'))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: appState.customers.length,
                      itemBuilder: (_, i) {
                        final c = appState.customers[i];
                        return ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone.isEmpty ? 'No phone' : c.phone),
                          trailing: Text(
                            '₹${c.creditBalance.toStringAsFixed(0)} due',
                            style: TextStyle(
                              color: c.creditBalance > 0
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}