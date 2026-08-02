import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';

void main() {
  test('relationship contexts have learner-facing safety guidance', () {
    expect(
      SmalltalkRelationshipContext.classmate.labelFor('de'),
      'Kursbekanntschaft',
    );
    expect(
      SmalltalkRelationshipContext.closeFriend.labelFor('en'),
      'close friend',
    );
    expect(
      SmalltalkRelationshipContext.service.labelFor('de'),
      'Service-Situation',
    );
  });
}
