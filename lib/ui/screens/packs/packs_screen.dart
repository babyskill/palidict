import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/pack_manifest.dart';
import '../../../data/database/pack_manager.dart';
import '../../../l10n/app_localizations.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  final PackManager _packManager = PackManager.instance;
  Map<String, String> _storageInfo = {
    'lite': PackManifest.lite.formattedInstalledSize,
    'core': '0 MB',
  };

  @override
  void initState() {
    super.initState();
    _packManager.addListener(_onPackChange);
    _loadStorage();
  }

  @override
  void dispose() {
    _packManager.removeListener(_onPackChange);
    super.dispose();
  }

  void _onPackChange() {
    if (mounted) {
      _loadStorage();
      setState(() {});
    }
  }

  Future<void> _loadStorage() async {
    final info = await _packManager.getStorageInfo();
    if (mounted) {
      setState(() {
        _storageInfo = info;
      });
    }
  }

  Future<void> _handleDownload() async {
    try {
      await _packManager.downloadCorePack();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.sideloadSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final errorDetails = _packManager.lastError ?? PackErrorDetails.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorDetails.toLocalizedMessage(l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.btnConfirmDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _packManager.deleteCorePack();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.packErrorDelete),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSideload() async {
    final l10n = AppLocalizations.of(context)!;
    final pathController = TextEditingController(text: 'data/core_final.db.gz');

    final chosenPath = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.btnSideload),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sideloadPrompt),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '/path/to/core_final.db or core_final.db.gz',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(pathController.text.trim()),
            child: Text(l10n.close),
          ),
        ],
      ),
    );

    if (chosenPath != null && chosenPath.isNotEmpty) {
      try {
        await _packManager.sideloadCorePack(chosenPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sideloadSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorDetails = _packManager.lastError ?? PackErrorDetails.fromException(e);
          final message = errorDetails.kind == PackErrorKind.verificationMismatch
              ? l10n.packErrorSideloadMismatch
              : l10n.packErrorSideload;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isCoreActive = _packManager.isCoreActive;
    final status = _packManager.coreStatus;

    final activePackName = isCoreActive ? l10n.packCoreTitle : l10n.packLiteTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPacks),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.desktopMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Active Pack Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.activePack(activePackName),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lite: ${_storageInfo['lite']} | Core: ${_storageInfo['core']}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Lite Pack Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              l10n.packLiteTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bundled (${PackManifest.lite.formattedInstalledSize})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.packLiteDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.installedSize(PackManifest.lite.formattedInstalledSize),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Core Pack Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              l10n.packCoreTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final isDark = theme.brightness == Brightness.dark;
                                final statusColor = isCoreActive
                                    ? (isDark ? const Color(0xFF81C784) : Colors.green)
                                    : status == PackStatus.error
                                        ? (isDark ? const Color(0xFFFF8A80) : Colors.red)
                                        : (isDark ? const Color(0xFFB0BEC5) : Colors.grey);
                                final statusBg = isCoreActive
                                    ? (isDark ? const Color(0xFF1B3B22) : Colors.green.withValues(alpha: 0.15))
                                    : status == PackStatus.error
                                        ? (isDark ? const Color(0xFF441818) : Colors.red.withValues(alpha: 0.15))
                                        : (isDark ? const Color(0xFF2C2A28) : Colors.grey.withValues(alpha: 0.15));

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCoreActive
                                        ? l10n.statusInstalled
                                        : status == PackStatus.error
                                            ? l10n.statusError
                                            : l10n.statusNotInstalled,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.packCoreDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Text(
                            l10n.downloadSize(PackManifest.core.formattedDownloadSize!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            l10n.installedSize(PackManifest.core.formattedInstalledSize),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Indicator / Actions
                      if (status == PackStatus.downloading) ...[
                        Text(l10n.statusDownloading((_packManager.downloadProgress * 100).toInt())),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: _packManager.downloadProgress),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _packManager.cancelDownload,
                          child: Text(l10n.btnCancel),
                        ),
                      ] else if (status == PackStatus.extracting) ...[
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.statusExtracting),
                          ],
                        ),
                      ] else if (isCoreActive) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: _handleDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.btnDeleteCore),
                        ),
                      ] else ...[
                        if (status == PackStatus.error) ...[
                          Builder(
                            builder: (context) {
                              final errorDetails = _packManager.lastError ??
                                  (_packManager.statusMessage != null
                                      ? PackErrorDetails.fromException(_packManager.statusMessage!)
                                      : const PackErrorDetails(kind: PackErrorKind.network));
                              final isDark = theme.brightness == Brightness.dark;
                              final errColor = isDark ? const Color(0xFFFF8A80) : Colors.red;
                              return Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF381818)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFFEF5350).withValues(alpha: 0.5)
                                        : Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: errColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorDetails.toLocalizedMessage(l10n),
                                        style: TextStyle(color: errColor, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _handleDownload,
                              icon: const Icon(Icons.download),
                              label: Text(l10n.btnDownloadCore),
                            ),
                            OutlinedButton.icon(
                              onPressed: _handleSideload,
                              icon: const Icon(Icons.folder_open),
                              label: Text(l10n.btnSideload),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
