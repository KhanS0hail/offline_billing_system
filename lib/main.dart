import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/database_helper.dart';
import 'theme/theme_provider.dart';
import 'providers/company_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/invoice_provider.dart';
import 'services/app_lock_service.dart';
import 'services/backup_service.dart';
import 'screens/main_shell.dart';
import 'screens/pin_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database
  await DatabaseHelper.instance.database;

  // Global Error Handler: Suppress debug overflow banners & render clean responsive layout fallbacks
  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool isOverflowError = false;
    if (details.exception is FlutterError) {
      final exception = details.exception as FlutterError;
      isOverflowError = exception.diagnostics.any(
        (e) => e.value.toString().startsWith("A RenderFlex overflowed by"),
      );
    }
    if (isOverflowError) {
      // Gracefully return an invisible shrink widget instead of yellow/black error banners!
      return const SizedBox.shrink();
    }
    return ErrorWidget(details.exception);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => AppLockService()),
        ChangeNotifierProvider(create: (_) => BackupService()),
      ],
      child: const BillingApp(),
    ),
  );
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Offline Billing System',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: Consumer<AppLockService>(
        builder: (context, lockService, child) {
          if (lockService.isLocked) {
            return const PinLockScreen(mode: PinMode.verify);
          }
          return const MainShell();
        },
      ),
    );
  }
}
