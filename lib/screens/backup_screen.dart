import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/google_drive_service.dart';
import '../services/app_lock_service.dart';
import 'pin_lock_screen.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'mmunsuri03@gmail.com');

  void _showConnectDialog(BuildContext context, GoogleDriveService driveService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Google email address for cloud backup:'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Google Account Email',
                prefixIcon: Icon(Icons.email_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isNotEmpty) {
                await driveService.connectAccount(email);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driveService = Provider.of<GoogleDriveService>(context);
    final lockService = Provider.of<AppLockService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GOOGLE DRIVE CLOUD SYNC CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Google Drive Auto-Sync', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(
                                driveService.isConnected
                                    ? 'Connected to ${driveService.accountEmail}'
                                    : 'Backup database & assets to personal Google Drive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: driveService.isConnected ? Colors.green.shade700 : Colors.grey,
                                  fontWeight: driveService.isConnected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (driveService.isConnected)
                          IconButton(
                            icon: const Icon(Icons.link_off_rounded, color: Colors.red),
                            tooltip: 'Disconnect Account',
                            onPressed: () => driveService.disconnectAccount(),
                          ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (driveService.isConnected) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Last Backup Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Chip(
                            avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            label: Text(
                              driveService.lastSyncTimestamp != null
                                  ? 'Synced (${driveService.lastSyncTimestamp})'
                                  : 'Not synced yet',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: driveService.isSyncing
                                  ? null
                                  : () async {
                                      final success = await driveService.backupToCloud();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success ? 'Cloud Backup Successful!' : 'Backup Failed!'),
                                          ),
                                        );
                                      }
                                    },
                              icon: driveService.isSyncing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.cloud_upload_rounded),
                              label: const Text('Backup Now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: driveService.isSyncing
                                  ? null
                                  : () async {
                                      final success = await driveService.restoreFromCloud();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success ? 'Database Restored Successfully!' : 'Restore Failed!'),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.cloud_download_rounded),
                              label: const Text('Restore Data'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showConnectDialog(context, driveService),
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                          label: const Text('Connect Google Account'),
                        ),
                      ),
                    ],
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
                              Text('App Security & PIN Lock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text('Protect billing data with 4-digit passcode', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                builder: (_) => const PinLockScreen(mode: PinMode.create),
                              ),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PinLockScreen(mode: PinMode.create),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        title: const Text('Remove Security PIN', style: TextStyle(color: Colors.red)),
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
