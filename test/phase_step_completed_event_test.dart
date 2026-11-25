import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/phase_task_panel.dart';

void main() {
  group('newlyCompletedSteps', () {
    test('reports only steps that flipped from not done to done', () {
      expect(
        newlyCompletedSteps(
          [true, false, false, false],
          [true, true, false, true],
        ),
        [1, 3],
      );
    });

    test('an already done step is never reported again', () {
      expect(newlyCompletedSteps([true, true], [true, true]), isEmpty);
    });

    test('a step that became undone is not an event', () {
      expect(newlyCompletedSteps([true, false], [false, false]), isEmpty);
    });

    test('a changed step layout reports nothing instead of guessing', () {
      expect(newlyCompletedSteps([false, false], [true, true, true]), isEmpty);
      expect(newlyCompletedSteps(const [], const []), isEmpty);
    });
  });
}
