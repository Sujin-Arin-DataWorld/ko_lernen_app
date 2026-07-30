import 'package:flutter/foundation.dart';

/// Lossless classification for a remote read.
///
/// Only [CloudReadState.absent] means the remote object was authoritatively
/// observed not to exist. Every other non-present state must fail closed.
enum CloudReadState { present, absent, unavailable, invalid, tooLarge }

@immutable
class CloudReadResult<T> {
  const CloudReadResult._({required this.state, this.value, this.revision});

  const CloudReadResult.present(T value, {int? revision})
    : this._(state: CloudReadState.present, value: value, revision: revision);

  const CloudReadResult.absent() : this._(state: CloudReadState.absent);

  const CloudReadResult.unavailable()
    : this._(state: CloudReadState.unavailable);

  const CloudReadResult.invalid() : this._(state: CloudReadState.invalid);

  const CloudReadResult.tooLarge() : this._(state: CloudReadState.tooLarge);

  final CloudReadState state;
  final T? value;

  /// Monotonic remote revision when the backing store exposes one.
  final int? revision;

  bool get isPresent => state == CloudReadState.present;
}
