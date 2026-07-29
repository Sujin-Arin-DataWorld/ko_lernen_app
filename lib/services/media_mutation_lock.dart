import 'dart:async';

class MediaMutationLock {
  static Future<void> _tail = Future<void>.value();

  static Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final previous = _tail;
    final next = previous.then<void>(
      (_) async {
        try {
          completer.complete(await operation());
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      onError: (_) async {
        try {
          completer.complete(await operation());
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    _tail = next;
    return completer.future;
  }
}
