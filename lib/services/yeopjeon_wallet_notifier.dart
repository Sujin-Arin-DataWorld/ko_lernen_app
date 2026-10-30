import 'package:flutter/foundation.dart';

import '../models/yeopjeon_wallet.dart';
import 'local_data_lifetime.dart';
import 'yeopjeon_service.dart';

@immutable
class YeopjeonWalletReadState {
  const YeopjeonWalletReadState({
    this.wallet,
    this.loading = false,
    this.failed = false,
  });
  final YeopjeonWallet? wallet;
  final bool loading;
  final bool failed;
}

/// Shell-owned, read-only view of the confirmed ledger shared by all five tabs.
class YeopjeonWalletNotifier extends ValueNotifier<YeopjeonWalletReadState> {
  YeopjeonWalletNotifier({Future<YeopjeonWallet?> Function()? loader})
    : _loader = loader ?? _read,
      super(const YeopjeonWalletReadState()) {
    LocalDataLifetime.changes.addListener(invalidate);
  }

  final Future<YeopjeonWallet?> Function() _loader;
  int _generation = 0;
  bool _disposed = false;

  static Future<YeopjeonWallet?> _read() async {
    final raw = await YeopjeonService.captureBackupJson();
    return raw == null ? null : YeopjeonWallet.decode(raw);
  }

  void invalidate() {
    _generation++;
    if (!_disposed) {
      value = const YeopjeonWalletReadState();
    }
  }

  Future<void> refresh({bool clear = false}) async {
    final generation = ++_generation;
    final lifetime = LocalDataLifetime.capture();
    if (_disposed) {
      return;
    }
    value = YeopjeonWalletReadState(
      wallet: clear ? null : value.wallet,
      loading: true,
    );
    try {
      final wallet = await _loader();
      if (!_disposed && generation == _generation && lifetime.isCurrent) {
        value = YeopjeonWalletReadState(wallet: wallet);
      }
    } catch (_) {
      if (!_disposed && generation == _generation && lifetime.isCurrent) {
        value = const YeopjeonWalletReadState(failed: true);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    LocalDataLifetime.changes.removeListener(invalidate);
    super.dispose();
  }
}
