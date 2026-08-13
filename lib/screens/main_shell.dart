import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Placeholder screens for Day 1
  final List<Widget> _screens = [
    const Center(child: Text("Dashboard Screen (Coming Soon)")),
    const Center(child: Text("Invoices Screen (Coming Soon)")),
    const Center(child: Text("Products & Inventory (Coming Soon)")),
    const Center(child: Text("Customers (Coming Soon)")),
    const Center(child: Text("Settings (Coming Soon)")),
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
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ThemeProvider themeProvider) {
    return Drawer(
      child: _buildNavigationList(themeProvider),
    );
  }

  Widget _buildSidebar(ThemeProvider themeProvider) {
    return Container(
      width: 250,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "Billing System",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
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
        // Close drawer on mobile
        if (MediaQuery.of(context).size.width < 800 && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }
}
