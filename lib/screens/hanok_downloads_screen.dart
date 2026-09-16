import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/hanok_assets/hanok_asset_delivery.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

class HanokDownloadsScreen extends StatefulWidget {
  const HanokDownloadsScreen({super.key, this.delivery});

  final HanokAssetDelivery? delivery;

  @override
  State<HanokDownloadsScreen> createState() => _HanokDownloadsScreenState();
}

class _HanokDownloadsScreenState extends State<HanokDownloadsScreen> {
  late HanokAssetDelivery _delivery;
  List<HanokPackStatus>? _statuses;
  final Set<String> _busyPacks = <String>{};
  final Map<String, HanokAssetFailure> _removeFailures =
      <String, HanokAssetFailure>{};
  Object? _pageError;
  Future<void>? _refreshJob;
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery ?? HanokAssetDelivery.shared;
    _delivery.addListener(_deliveryChanged);
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(covariant HanokDownloadsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.delivery ?? HanokAssetDelivery.shared;
    if (!identical(next, _delivery)) {
      _delivery.removeListener(_deliveryChanged);
      _delivery = next;
      _delivery.addListener(_deliveryChanged);
      _statuses = null;
      _busyPacks.clear();
      _removeFailures.clear();
      _pageError = null;
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _delivery.removeListener(_deliveryChanged);
    super.dispose();
  }

  void _deliveryChanged() => unawaited(_refresh());

  Future<void> _refresh() {
    _refreshPending = true;
    final active = _refreshJob;
    if (active != null) {
      return active;
    }
    final job = _drainRefreshes();
    _refreshJob = job;
    return job.whenComplete(() {
      if (identical(_refreshJob, job)) {
        _refreshJob = null;
      }
    });
  }

  Future<void> _drainRefreshes() async {
    while (_refreshPending) {
      _refreshPending = false;
      try {
        final source = _delivery;
        final statuses = await source.statuses();
        if (!mounted) {
          return;
        }
        if (!identical(source, _delivery)) {
          _refreshPending = true;
          continue;
        }
        setState(() {
          _statuses = statuses;
          _pageError = null;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() => _pageError = error);
      }
    }
  }

  Future<void> _download(String packId) async {
    if (_busyPacks.contains(packId)) {
      return;
    }
    setState(() {
      _busyPacks.add(packId);
      _pageError = null;
    });
    try {
      await _delivery.downloadPack(packId, allowMobileData: true);
    } catch (_) {
      // The delivery service exposes a typed, localized-ready failure in status.
    } finally {
      if (mounted) {
        setState(() => _busyPacks.remove(packId));
        await _refresh();
      }
    }
  }

  Future<void> _remove(String packId) async {
    if (_busyPacks.contains(packId)) {
      return;
    }
    setState(() {
      _busyPacks.add(packId);
      _removeFailures.remove(packId);
    });
    try {
      await _delivery.removePack(packId);
    } catch (error) {
      if (mounted) {
        setState(() {
          _removeFailures[packId] = error is HanokAssetFailure
              ? error
              : const HanokAssetFailure(HanokAssetFailureKind.storage);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busyPacks.remove(packId));
        await _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final statuses = _statuses;
    return SoriStandardFrame(
      appBarTitle: t.hanokDownloadsTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      builder: (context, padding) => ListView(
        key: const ValueKey('hanok-downloads-list'),
        padding: padding,
        children: [
          Text(t.hanokDownloadsIntro, style: SoriTextTheme.of(context).body),
          const SizedBox(height: Spacing.sm),
          Text(
            kIsWeb
                ? t.hanokDownloadsWebSessionNotice
                : t.hanokDownloadsRemovalNotice,
            style: SoriTextTheme.of(context).bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              t.hanokDownloadsRemovalNotice,
              style: SoriTextTheme.of(context).bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          if (statuses == null && _pageError == null)
            _StatusNotice(
              key: const ValueKey('hanok-downloads-loading'),
              icon: Icons.inventory_2_outlined,
              text: t.hanokDownloadsLoading,
            )
          else if (_pageError != null && statuses == null)
            _StatusNotice(
              key: const ValueKey('hanok-downloads-load-failed'),
              icon: Icons.error_outline_rounded,
              text: t.hanokDownloadsLoadFailed,
              action: SoriButton.outlined(
                label: t.hanokAssetsRetry,
                onTap: _refresh,
              ),
            )
          else ...[
            if (_pageError != null) ...[
              _StatusNotice(
                icon: Icons.error_outline_rounded,
                text: t.hanokDownloadsLoadFailed,
              ),
              const SizedBox(height: Spacing.md),
            ],
            for (final status in statuses!) ...[
              _PackCard(
                status: status,
                busy: _busyPacks.contains(status.pack.id),
                removeFailure: _removeFailures[status.pack.id],
                onDownload: () => _download(status.pack.id),
                onRemove: () => _remove(status.pack.id),
              ),
              const SizedBox(height: Spacing.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.status,
    required this.busy,
    required this.removeFailure,
    required this.onDownload,
    required this.onRemove,
  });

  final HanokPackStatus status;
  final bool busy;
  final HanokAssetFailure? removeFailure;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final title = status.pack.title[language] ?? status.pack.title['en']!;
    final progress = status.pack.totalBytes == 0
        ? 0.0
        : status.availableBytes / status.pack.totalBytes;
    final isWorking = busy || status.isDownloading;
    final actionableFailure =
        status.failure != null &&
        status.failure!.kind != HanokAssetFailureKind.explicitDownloadNeeded;
    return SoriCard(
      key: ValueKey('hanok-download-pack-${status.pack.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: SoriTextTheme.of(context).h3),
          const SizedBox(height: Spacing.xs),
          Text(
            t.hanokDownloadsSize(_formatBytes(status.pack.totalBytes, locale)),
            style: SoriTextTheme.of(context).bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          SoriProgressBar(value: progress.clamp(0, 1), animated: false),
          const SizedBox(height: Spacing.xs),
          Text(
            _statusText(context),
            key: ValueKey('hanok-download-status-${status.pack.id}'),
            style: SoriTextTheme.of(context).bodySmall,
          ),
          if (actionableFailure || removeFailure != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              removeFailure != null
                  ? t.hanokDownloadsRemoveFailed
                  : _failureText(context, status.failure!),
              key: ValueKey('hanok-download-failure-${status.pack.id}'),
              style: SoriTextTheme.of(
                context,
              ).bodySmall.copyWith(color: SoriColors.danger),
            ),
          ],
          if (!status.isBundled || status.storedBytes > 0) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                if (!status.isComplete || actionableFailure)
                  SoriButton.filled(
                    key: ValueKey('hanok-download-action-${status.pack.id}'),
                    label: actionableFailure
                        ? t.hanokAssetsRetry
                        : t.hanokAssetsDownloadNow,
                    onTap: isWorking ? null : onDownload,
                  ),
                if (status.storedBytes > 0)
                  SoriButton.outlined(
                    key: ValueKey('hanok-remove-action-${status.pack.id}'),
                    label: removeFailure != null
                        ? t.hanokAssetsRetry
                        : t.hanokDownloadsRemove,
                    destructive: true,
                    onTap: isWorking ? null : onRemove,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = Localizations.localeOf(context);
    if (status.isBundled) {
      return t.hanokDownloadsIncluded;
    }
    if (status.isDownloading || busy) {
      return t.hanokDownloadsDownloading(
        _formatBytes(status.availableBytes, locale),
        _formatBytes(status.pack.totalBytes, locale),
      );
    }
    if (status.isComplete) {
      return kIsWeb
          ? t.hanokDownloadsAvailableThisSession
          : t.hanokDownloadsAvailableOffline;
    }
    if (status.availableBytes > 0) {
      return t.hanokDownloadsPartial(
        _formatBytes(status.availableBytes, locale),
        _formatBytes(status.pack.totalBytes, locale),
      );
    }
    return t.hanokDownloadsNotDownloaded;
  }

  String _failureText(BuildContext context, HanokAssetFailure failure) {
    final t = AppL10n.of(context);
    return switch (failure.kind) {
      HanokAssetFailureKind.cacheFull => t.hanokAssetsStorageFull,
      HanokAssetFailureKind.network => t.hanokAssetsNetworkFailed,
      HanokAssetFailureKind.explicitDownloadNeeded =>
        t.hanokAssetsCellularNeeded,
      HanokAssetFailureKind.corrupt ||
      HanokAssetFailureKind.storage ||
      HanokAssetFailureKind.removed ||
      HanokAssetFailureKind.unknownAsset => t.hanokAssetsImageFailed,
    };
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SoriCard(
    child: Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: Spacing.sm),
        Text(text, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: Spacing.md), action!],
      ],
    ),
  );
}

String _formatBytes(int bytes, Locale locale) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final decimal = NumberFormat('0.0', locale.toLanguageTag());
  if (bytes < 1024 * 1024) {
    return '${decimal.format(bytes / 1024)} KB';
  }
  return '${decimal.format(bytes / (1024 * 1024))} MB';
}
