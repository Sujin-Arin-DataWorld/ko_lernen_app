import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:flutter_test/flutter_test.dart';

// S2 (net timeouts/backoff) regression guard.
//
// Scans the three sync-path service files for an `await`-governed call to a
// Firestore/Storage/callable network primitive (`.get(`, `.set(`, `.update(`,
// `.runTransaction(`, a non-null-aware `.call(` — i.e. not `?.call(`, which in
// this codebase is always a local Dart callback invocation, never a Firebase
// callable — `getDownloadURL(`, `getData(`) that is not bounded by
// `withNetTimeout(` — either directly (`await withNetTimeout(x.get(), ...)`)
// or by enclosure (the call sits inside a callback/expression that is itself
// an argument to `withNetTimeout(...)`, e.g. the `transaction.get(...)` calls
// inside `firestore.runTransaction((transaction) async { ... })` once the
// whole `runTransaction(...)` call is wrapped).
//
// RED baseline (measured by running this exact detector, as a standalone
// script, against the pre-S2 file contents at origin/main@a185bba8, before
// any `withNetTimeout` existed):
//   cloud_sync.dart................... 1   (lastBackupAt's ref.get())
//   firestore_progress_service.dart... 10  (loadAll; _readFirestorePacks;
//                                            _readMembershipOnce;
//                                            _readFirestorePack; the CAS
//                                            runTransaction's 2 inner
//                                            transaction.get() calls;
//                                            savePackWithResult's
//                                            runTransaction + its 1 inner
//                                            transaction.get(); and
//                                            saveManyWithSession's
//                                            runTransaction + its 1 inner
//                                            transaction.get())
//   access_snapshot_service.dart...... 1   (the httpsCallable(...).call())
//   TOTAL.............................. 12
// GREEN after S2: all 12 are wrapped in withNetTimeout (see the S2 PR
// description for the exhaustive file:line -> scope table).
//
// Known scanner blind spot (not part of the 12 above, fixed anyway): this
// detector requires a literal `await` token governing the call. Two write
// sites hand the Firestore call to a generic `Future<void> Function() write`
// parameter that is awaited *elsewhere* (`cloud_sync.dart`'s
// `ref!.set(...)` inside `backupWithSession`'s injected `write:` closure) —
// there is no literal "await ... .set(" in the source for a textual scanner
// to find. That site was found and wrapped by manual review (see the PR's
// file:line table) and is covered by its own behavior test
// (`test/services/cloud_sync_net_timeout_test.dart`), not by this guard.
//
// `knownUnboundedAwaitCap` is 0 — there is no accepted residual among the 12
// sites this detector can see. The background pack queue retains its actual
// transaction acknowledgement after a bounded caller wait. Only its exact
// transaction and membership read are checked through the separate contract
// below; no method-wide exclusion or increased residual cap is allowed.
// A new awaited call to one of these primitives
// on these three files must be wrapped in `withNetTimeout` or this guard
// fails.
const int knownUnboundedAwaitCap = 0;

const List<String> _targetFiles = [
  'lib/services/cloud_sync.dart',
  'lib/services/firestore_progress_service.dart',
  'lib/services/access_snapshot_service.dart',
];

final List<RegExp> _networkCallPatterns = [
  RegExp(r'\.get\('),
  RegExp(r'\.set\('),
  RegExp(r'\.update\('),
  RegExp(r'\.runTransaction\('),
  // Deliberately excludes `?.call(` — every null-aware `.call(` in these
  // files invokes a local Dart callback parameter, not a Firebase callable.
  RegExp(r'(?<!\?)\.call\('),
  RegExp(r'getDownloadURL\('),
  RegExp(r'getData\('),
];

bool _isIdentifierChar(String ch) => RegExp(r'[A-Za-z0-9_$]').hasMatch(ch);

/// Blanks out `//` line comments and string-literal bodies (keeping length
/// and line breaks intact) so stray parentheses in prose comments or string
/// contents cannot confuse the bracket-depth walks below.
String _stripNoise(String src) {
  final buffer = StringBuffer();
  var i = 0;
  final n = src.length;
  while (i < n) {
    final ch = src[i];
    if (ch == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        buffer.write(' ');
        i++;
      }
      continue;
    }
    if (ch == "'" || ch == '"') {
      final quote = ch;
      final triple = i + 2 < n && src[i + 1] == quote && src[i + 2] == quote;
      final quoteLen = triple ? 3 : 1;
      buffer.write(' ' * quoteLen);
      i += quoteLen;
      while (i < n) {
        final c = src[i];
        if (c == r'\' && i + 1 < n) {
          buffer.write('  ');
          i += 2;
          continue;
        }
        if (triple &&
            i + 2 < n &&
            src[i] == quote &&
            src[i + 1] == quote &&
            src[i + 2] == quote) {
          buffer.write('   ');
          i += 3;
          break;
        }
        if (!triple && c == quote) {
          buffer.write(' ');
          i += 1;
          break;
        }
        buffer.write(c == '\n' ? '\n' : ' ');
        i++;
      }
      continue;
    }
    buffer.write(ch);
    i++;
  }
  return buffer.toString();
}

String _precedingIdentifier(String src, int openParenIndex) {
  var j = openParenIndex - 1;
  while (j >= 0 &&
      (src[j] == ' ' || src[j] == '\n' || src[j] == '\t' || src[j] == '\r')) {
    j--;
  }
  final end = j + 1;
  while (j >= 0 && _isIdentifierChar(src[j])) {
    j--;
  }
  final start = j + 1;
  return start < end ? src.substring(start, end) : '';
}

String _matchingCloser(String opener) => switch (opener) {
  '(' => ')',
  '[' => ']',
  _ => '}',
};

/// Is [matchIndex] governed by a literal `await` within its *own* statement
/// (tunnelling through balanced sub-expressions like `.doc(uid).collection(x)`,
/// but stopping at a real statement-terminating `;` or as soon as we'd have
/// to pop into an *enclosing* call/block to keep looking)?
///
/// This intentionally does NOT chase `await` across statement boundaries —
/// that would misattribute an unrelated preceding `await` to a later,
/// un-awaited call (e.g. a bare `transaction.set(...)` after some earlier
/// `await` in the same block).
bool _isDirectlyAwaited(String src, int matchIndex) {
  var i = matchIndex - 1;
  final stack = <String>[];
  var budget = 4000;
  while (i >= 0 && budget > 0) {
    budget--;
    final ch = src[i];
    if (stack.isEmpty) {
      if (ch == ';') {
        return false;
      }
      if (ch == 't' && i >= 4 && src.substring(i - 4, i + 1) == 'await') {
        final beforeIdx = i - 5;
        final before = beforeIdx >= 0 ? src[beforeIdx] : ' ';
        if (!_isIdentifierChar(before)) {
          return true;
        }
      }
    }
    if (ch == ')' || ch == ']' || ch == '}') {
      stack.add(ch);
    } else if (ch == '(' || ch == '[' || ch == '{') {
      if (stack.isEmpty) {
        // Popped out into an enclosing call/block without finding `await` in
        // this statement — not directly awaited.
        return false;
      }
      if (stack.last == _matchingCloser(ch)) {
        stack.removeLast();
      }
    }
    i--;
  }
  return false;
}

/// Is [matchIndex] textually nested — at any depth, through balanced
/// parens/brackets/braces (so a callback body passed as an argument is
/// transparent) — inside a `withNetTimeout(...)` call's argument list? This
/// is the "same statement or enclosing expression" wrapping check and
/// deliberately climbs across statement boundaries (e.g. past sibling
/// `transaction.get(...)` statements inside the same wrapped
/// `runTransaction((transaction) async { ... })` callback).
bool _isWrappedByNetTimeout(String src, int matchIndex) {
  var i = matchIndex - 1;
  final stack = <String>[];
  var budget = 100000;
  while (i >= 0 && budget > 0) {
    budget--;
    final ch = src[i];
    if (ch == ')' || ch == ']' || ch == '}') {
      stack.add(ch);
    } else if (ch == '(' || ch == '[' || ch == '{') {
      if (stack.isEmpty) {
        if (ch == '(' && _precedingIdentifier(src, i) == 'withNetTimeout') {
          return true;
        }
        // Popped into an enclosing call/block that isn't withNetTimeout —
        // keep climbing, it may itself be wrapped further out.
      } else if (stack.last == _matchingCloser(ch)) {
        stack.removeLast();
      }
    }
    i--;
  }
  return false;
}

List<String> _unboundedAwaitsIn(String path, String content) {
  final cleaned = _stripNoise(content);
  final retainedSites = path == 'lib/services/firestore_progress_service.dart'
      ? _retainedPackWriteSites(content, cleaned)
      : <int>{};
  final violations = <String>[];
  for (final pattern in _networkCallPatterns) {
    for (final match in pattern.allMatches(cleaned)) {
      if (!_isDirectlyAwaited(cleaned, match.start)) {
        continue;
      }
      if (_isWrappedByNetTimeout(cleaned, match.start)) {
        continue;
      }
      if (retainedSites.contains(match.start)) {
        continue;
      }
      final line =
          '\n'.allMatches(cleaned.substring(0, match.start)).length + 1;
      violations.add('$path:$line: ${match.group(0)}');
    }
  }
  return violations;
}

class _Calls extends RecursiveAstVisitor<void> {
  final methods = <MethodDeclaration>[];
  final calls = <MethodInvocation>[];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methods.add(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(node);
    super.visitMethodInvocation(node);
  }
}

Set<int> _retainedPackWriteSites(String source, String cleaned) {
  final nodes = _Calls();
  parseString(content: source).unit.accept(nodes);
  final wrapper = nodes.methods
      .where((m) => m.name.lexeme == 'savePackWithResult')
      .single;
  final boundedAck = nodes.calls.where(
    (call) =>
        call.methodName.name == 'savePackAcknowledged' &&
        call.offset >= wrapper.offset &&
        call.end <= wrapper.end &&
        _isWrappedByNetTimeout(cleaned, call.offset),
  );
  if (boundedAck.length != 1) {
    return {};
  }
  final raw = nodes.methods
      .where((m) => m.name.lexeme == 'savePackAcknowledged')
      .single;
  final transactions = nodes.calls.where(
    (call) =>
        call.offset >= raw.offset &&
        call.end <= raw.end &&
        call.target?.toSource() == 'db' &&
        call.methodName.name == 'runTransaction',
  );
  if (transactions.length != 1) {
    return {};
  }
  final transaction = transactions.single;
  final membershipReads = nodes.calls.where(
    (call) =>
        call.offset > transaction.offset &&
        call.end < transaction.end &&
        call.target?.toSource() == 'transaction' &&
        call.methodName.name == 'get' &&
        call.argumentList.toSource() == '(membershipRef)',
  );
  if (membershipReads.length != 1) {
    return {};
  }
  return {
    transaction.methodName.offset - 1,
    membershipReads.single.methodName.offset - 1,
  };
}

void main() {
  test(
    'retained pack acknowledgement has only bounded or retaining callers',
    () {
      final references = <String>[];
      for (final file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final count = RegExp(
          r'\bsavePackAcknowledged\b',
        ).allMatches(_stripNoise(file.readAsStringSync())).length;
        for (var i = 0; i < count; i++) {
          references.add(file.path.replaceAll('\\', '/'));
        }
      }
      expect(references..sort(), [
        'lib/services/firestore_progress_service.dart',
        'lib/services/firestore_progress_service.dart',
        'lib/services/pack_sync_queue.dart',
      ]);
    },
  );

  test(
    'removing bounded wrapper or adding raw reads still fails the guard',
    () {
      const path = 'lib/services/firestore_progress_service.dart';
      final source = File(path).readAsStringSync().replaceAll('\r\n', '\n');
      final withoutWrapper = source.replaceFirst(
        'return await withNetTimeout(\n        savePackAcknowledged(p),',
        'return await unboundedWait(\n        savePackAcknowledged(p),',
      );
      expect(withoutWrapper, isNot(source));
      expect(_unboundedAwaitsIn(path, withoutWrapper), hasLength(2));
      final extraRead = source.replaceFirst(
        'final membershipSnapshot = await transaction.get(membershipRef);',
        'await transaction.get(otherRef);\n'
            'final membershipSnapshot = await transaction.get(membershipRef);',
        source.indexOf('static Future<CloudWriteResult> savePackAcknowledged'),
      );
      expect(extraRead, isNot(source));
      expect(_unboundedAwaitsIn(path, extraRead), hasLength(1));
    },
  );

  test('every awaited Firestore/Storage/callable call on the sync paths is '
      'bounded by withNetTimeout', () {
    final violations = <String>[];
    for (final path in _targetFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path must exist');
      violations.addAll(_unboundedAwaitsIn(path, file.readAsStringSync()));
    }
    expect(
      violations.length,
      lessThanOrEqualTo(knownUnboundedAwaitCap),
      reason:
          'Unbounded awaited network call(s) — wrap with withNetTimeout '
          '(see lib/services/net/sori_net.dart), or justify a residual and '
          'raise knownUnboundedAwaitCap with a comment explaining why:\n'
          '${violations.join('\n')}',
    );
  });
}
