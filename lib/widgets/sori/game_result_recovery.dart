import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/local_data_lifetime.dart';
import '../app_error.dart';
import '../app_loading.dart';
import 'game_reward.dart';
import 'study_frame.dart';

/// Holds one round's completion open across retry, with the usual study exits.
/// Call resetGameResult when admitting a new round. A cancelled/retired round
/// resolves to null, so callers must check before publishing their result.
mixin GameResultRecovery<T extends StatefulWidget> on State<T> {
  final _gameLifetime = LocalDataLifetime.capture();
  GameResultAttempt? _gameAttempt;
  Completer<GameOutcome?>? _gameCompletion;
  bool _gameSaving = false;
  bool _gameFailed = false;
  bool _gameExpired = false;
  bool _gameRetired = false;
  ModalRoute<dynamic>? _gameRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gameRoute = ModalRoute.of(context);
  }

  bool get _gameRouteIsActive => _gameRoute?.isActive ?? true;

  /// Guards retained input callbacks as well as visible controls.
  bool get gameResultAcceptsInput =>
      mounted &&
      _gameRouteIsActive &&
      !_gameRetired &&
      !_gameSaving &&
      !_gameFailed &&
      _gameLifetime.isCurrent;

  void resetGameResult() {
    retireGameResult();
    _gameAttempt = null;
    _gameCompletion = null;
    _gameSaving = false;
    _gameFailed = false;
    _gameExpired = false;
    _gameRetired = false;
  }

  Future<GameOutcome?> saveGameResult({
    required String gameId,
    required int xp,
    int? score,
    bool higherIsBetter = true,
    int? dailyCompletionBonus,
    bool kkeunmariWin = false,
  }) {
    if (!mounted || _gameRetired || !_gameRouteIsActive) {
      return Future.value(null);
    }
    if (!_gameLifetime.isCurrent) {
      setState(() {
        _gameExpired = true;
        _gameFailed = true;
        _gameRetired = true;
      });
      return Future.value(null);
    }
    if (_gameCompletion != null) {
      return _gameCompletion!.future;
    }
    _gameAttempt = GameResultAttempt(
      gameId: gameId,
      xp: xp,
      score: score,
      higherIsBetter: higherIsBetter,
      dailyCompletionBonus: dailyCompletionBonus,
      kkeunmariWin: kkeunmariWin,
    );
    _gameCompletion = Completer<GameOutcome?>();
    unawaited(_trySaveGameResult());
    return _gameCompletion!.future;
  }

  Future<void> _trySaveGameResult() async {
    final attempt = _gameAttempt;
    final completion = _gameCompletion;
    if (!mounted ||
        _gameRetired ||
        !_gameRouteIsActive ||
        _gameSaving ||
        attempt == null ||
        completion == null ||
        completion.isCompleted) {
      return;
    }
    setState(() {
      _gameSaving = true;
      _gameFailed = false;
    });
    try {
      final outcome = await attempt.save();
      if (!mounted || _gameRetired || !identical(attempt, _gameAttempt)) {
        return;
      }
      if (!_gameRouteIsActive) {
        retireGameResult();
        return;
      }
      completion.complete(outcome);
    } catch (error) {
      if (mounted &&
          _gameRouteIsActive &&
          !_gameRetired &&
          identical(attempt, _gameAttempt)) {
        setState(() {
          _gameFailed = true;
          _gameExpired = error is StaleLocalDataLifetimeException;
        });
      }
    } finally {
      if (mounted && identical(attempt, _gameAttempt)) {
        setState(() => _gameSaving = false);
      }
    }
  }

  /// Wire to every normal play frame as well as the recovery frame, so a
  /// delayed completion cannot start after a confirmed exit.
  void retireGameResult() {
    _gameRetired = true;
    _gameAttempt?.cancel();
    final completion = _gameCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete(null);
    }
  }

  Widget? gameResultRecoveryFrame(String title) {
    if (!_gameSaving && !_gameFailed && !_gameRetired) {
      return null;
    }
    final t = AppL10n.of(context);
    final attempt = _gameAttempt;
    return SoriStudyFrame(
      title: title,
      homeEscape: const SoriHomeEscape(confirmWhen: true),
      onLeave: retireGameResult,
      child: _gameSaving
          ? const AppLoading()
          : AppError(
              message: t.courseCheckpointSaveError,
              messageLiveRegion: true,
              retryLabel: _gameExpired || _gameRetired
                  ? t.btnClose
                  : t.btnRetry,
              onRetry: _gameExpired || _gameRetired
                  ? () => Navigator.of(context).maybePop()
                  : () {
                      if (identical(attempt, _gameAttempt)) {
                        unawaited(_trySaveGameResult());
                      }
                    },
            ),
    );
  }

  @override
  void dispose() {
    retireGameResult();
    super.dispose();
  }
}
