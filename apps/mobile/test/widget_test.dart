import 'package:flutter_test/flutter_test.dart';

import 'package:app_creditos/main.dart';

void main() {
  test('ChallengeModel parses challenge payload', () {
    final model = ChallengeModel.fromJson({
      'id': 7,
      'title': 'Reto técnico',
      'type': 'TECHNICAL_INSPECTOR',
      'itemsJson': [
        {'code': 'front', 'label': 'Frontal'},
        {'code': 'rear', 'label': 'Trasera'},
      ],
    });

    expect(model.id, 7);
    expect(model.type, ChallengeType.technicalInspector);
    expect(model.items.length, 2);
    expect(model.items.first.code, 'front');
    expect(model.items.last.label, 'Trasera');
    expect(model.toJson()['title'], 'Reto técnico');
  });
}
