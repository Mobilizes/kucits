import 'package:flutter_test/flutter_test.dart';

import 'package:kucits/main.dart';

void main() {
  testWidgets('KucITS timeline smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KucITSApp());
    expect(find.text('KucITS 🐱'), findsOneWidget);
  });
}
