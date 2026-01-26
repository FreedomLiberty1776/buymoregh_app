import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/payment_list_item.dart';
import 'payment_detail_screen.dart';

/// Lists payments that are saved locally but not yet synced to the server.
/// Shows a "Sync now" button to trigger the offline queue sync.
class UnsyncedPaymentsScreen extends StatefulWidget {
  const UnsyncedPaymentsScreen({super.key});

  @override
  State<UnsyncedPaymentsScreen> createState() => _UnsyncedPaymentsScreenState();
}

class _UnsyncedPaymentsScreenState extends State<UnsyncedPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadUnsyncedPayments(
            agentId: context.read<AuthProvider>().user?.id,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final unsynced = appProvider.unsyncedPayments;
    final hasPending = appProvider.hasPendingSync;
    final isSyncing = appProvider.isSyncingPending || appProvider.isSyncing;
    final isOnline = appProvider.isOnline;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Unsynced payments',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sync now bar
          if (hasPending || unsynced.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.warningColor.withOpacity(0.08),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOnline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off, size: 18, color: AppTheme.warningColor),
                            const SizedBox(width: 6),
                            Text(
                              'You\'re offline. Syncing will run when you\'re back online.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (isOnline && !isSyncing)
                            ? () async {
                                await appProvider.triggerSync(
                                  agentId: context.read<AuthProvider>().user?.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appProvider.hasPendingSync
                                            ? 'Some items could not be synced. Will retry when possible.'
                                            : 'Sync completed.',
                                      ),
                                      backgroundColor: appProvider.hasPendingSync
                                          ? AppTheme.warningColor
                                          : AppTheme.completedStatus,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload, size: 20),
                        label: Text(isSyncing ? 'Syncing...' : 'Sync now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: unsynced.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All payments are synced',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'New payments saved offline will appear here until they are sent to the server.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textHint,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: unsynced.length,
                    itemBuilder: (context, index) {
                      final payment = unsynced[index];
                      return PaymentListItem(
                        payment: payment,
                        showCustomerAndContractLine: true,
                        showProductName: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentDetailScreen(payment: payment),
                            ),
                          );
                          if (context.mounted) {
                            context.read<AppProvider>().loadUnsyncedPayments(
                                  agentId: context.read<AuthProvider>().user?.id,
                                );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
