import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/app_lock_service.dart';
import '../providers/company_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import 'pin_lock_screen.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    final backupService = Provider.of<BackupService>(context);
    final lockService = Provider.of<AppLockService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LOCAL FILE BACKUP & RESTORE CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.backup_rounded, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Database Backup & Restore',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(
                                'Export or import your billing database file',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Last Backup Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Backup:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Chip(
                          avatar: Icon(
                            backupService.lastBackupTimestamp != null
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: backupService.lastBackupTimestamp != null
                                ? Colors.green
                                : Colors.grey,
                            size: 16,
                          ),
                          label: Text(
                            backupService.lastBackupTimestamp ?? 'No backup yet',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Export Backup Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: backupService.isBusy
                            ? null
                            : () async {
                                final success = await backupService.exportBackup(context);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'Backup exported! Share via WhatsApp, Email, or save to Files.'
                                          : 'Export failed. Please try again.'),
                                    ),
                                  );
                                }
                              },
                        icon: backupService.isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file_rounded),
                        label: const Text('Export Backup'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share your database via WhatsApp, Email, USB, or save to your device storage.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    // Import / Restore Backup Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: backupService.isBusy
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Restore from Backup?'),
                                    content: const Text(
                                      'This will REPLACE all current invoices, customers, and products with the backup file data.\n\nAre you sure?',
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange),
                                        child: const Text('Yes, Restore'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await backupService.importBackup();
                                  if (context.mounted) {
                                    if (success) {
                                      // Reload all app providers with newly restored DB
                                      Provider.of<CompanyProvider>(context, listen: false).loadCompany();
                                      Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
                                      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
                                      Provider.of<ProductProvider>(context, listen: false).loadProducts();
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Database restored successfully! All data updated.'
                                            : 'Restore failed. Please select a valid .db backup file.'),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Import & Restore Backup'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick a .db backup file from your device to restore all data.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. APP SECURITY PIN LOCK CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.purple, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App Security & PIN Lock',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text('Protect billing data with 4-digit passcode',
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: const Text('Enable Security PIN'),
                      subtitle: Text(
                        lockService.isPinSet
                            ? 'Passcode protection is currently ACTIVE'
                            : 'No PIN code set yet',
                      ),
                      value: lockService.isPinEnabled && lockService.isPinSet,
                      onChanged: (val) async {
                        if (val) {
                          if (!lockService.isPinSet) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PinLockScreen(mode: PinMode.create)),
                            );
                          } else {
                            await lockService.setPinEnabled(true);
                          }
                        } else {
                          await lockService.setPinEnabled(false);
                        }
                      },
                    ),
                    if (lockService.isPinSet) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.password_rounded),
                        title: const Text('Change Security PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PinLockScreen(mode: PinMode.create)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        title: const Text('Remove Security PIN',
                            style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          await lockService.removePin();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Security PIN removed.')),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
