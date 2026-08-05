import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/widgets/sori/account_operation_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a newer durable read locks an already-ready sibling guard while it is pending',
    (tester) async {
      final first = ProductionAccountUiOperations(
        pendingStateReader: () async => AccountUiPendingState.none,
      );
      final delayedState = Completer<AccountUiPendingState>();
      final second = ProductionAccountUiOperations(
        pendingStateReader: () => delayedState.future,
      );
      final showSecond = ValueNotifier<bool>(false);
      addTearDown(showSecond.dispose);

      await tester.pumpWidget(
        _TwoGuardHarness(first: first, second: second, showSecond: showSecond),
      );
      await tester.pumpAndSettle();

      expect(_button(tester, 'first').onPressed, isNotNull);

      showSecond.value = true;
      // The sibling guard defers its admission read to a post-frame callback so
      // mounting never notifies the shared notifier mid-build (that would throw
      // "setState() called during build" inside a lazy list). The lock lands on
      // the frame after mount — settle before asserting it. The action layer
      // (link() re-reads pending state) is the real block, so this frame of lag
      // never admits an unsafe action.
      await tester.pumpAndSettle();

      expect(first.pendingState.value, AccountUiPendingState.loading);
      expect(_button(tester, 'first').onPressed, isNull);
      expect(_button(tester, 'second').onPressed, isNull);

      delayedState.complete(AccountUiPendingState.none);
      await tester.pumpAndSettle();

      expect(_button(tester, 'first').onPressed, isNotNull);
      expect(_button(tester, 'second').onPressed, isNotNull);
    },
  );
}

class _TwoGuardHarness extends StatelessWidget {
  const _TwoGuardHarness({
    required this.first,
    required this.second,
    required this.showSecond,
  });

  final ProductionAccountUiOperations first;
  final ProductionAccountUiOperations second;
  final ValueListenable<bool> showSecond;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: showSecond,
        builder: (context, secondVisible, _) => Column(
          children: [
            AccountNewLinkGuard(
              key: const ValueKey<String>('first-guard'),
              operations: first,
              builder: (context, available) => FilledButton(
                key: const ValueKey<String>('first'),
                onPressed: available ? () {} : null,
                child: const Text('first'),
              ),
            ),
            if (secondVisible)
              AccountNewLinkGuard(
                key: const ValueKey<String>('second-guard'),
                operations: second,
                builder: (context, available) => FilledButton(
                  key: const ValueKey<String>('second'),
                  onPressed: available ? () {} : null,
                  child: const Text('second'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

FilledButton _button(WidgetTester tester, String key) {
  return tester.widget<FilledButton>(find.byKey(ValueKey<String>(key)));
}
