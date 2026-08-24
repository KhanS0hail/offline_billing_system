import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/company_provider.dart';
import 'company_profile_screen.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ReportsScreen(),
    const InvoicesScreen(),
    const ProductsScreen(),
    const CustomersScreen(),
    const CompanyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text('Billing System'),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(themeProvider),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(themeProvider),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeProvider themeProvider) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildCompanyHeader(),
            const Divider(),
            Expanded(child: _buildNavigationList(themeProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Consumer<CompanyProvider>(
      builder: (context, provider, child) {
        final company = provider.company;
        final companyName = (company?.name != null && company!.name!.isNotEmpty)
            ? company.name!
            : "My Company";
        final logoBase64 = company?.logoBase64;
        final hasLogo = logoBase64 != null && logoBase64.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(logoBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.store_rounded,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.store_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Billing System",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(ThemeProvider themeProvider) {
    return SafeArea(
      child: Container(
        width: 250,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            _buildCompanyHeader(),
            const Divider(),
            Expanded(child: _buildNavigationList(themeProvider)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dark Mode"),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(value),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationList(ThemeProvider themeProvider) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _navItem(Icons.dashboard, "Dashboard", 0),
        _navItem(Icons.receipt, "Invoices", 1),
        _navItem(Icons.inventory, "Products", 2),
        _navItem(Icons.people, "Customers", 3),
        _navItem(Icons.settings, "Settings", 4),
      ],
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Refresh database state on menu selection
        if (index == 1) {
          Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
        } else if (index == 2) {
          Provider.of<ProductProvider>(context, listen: false).loadProducts();
        } else if (index == 3) {
          Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
        }

        // Close drawer on mobile
        if (MediaQuery.of(context).size.width < 800 && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }
}
