import 'package:flutter_test/flutter_test.dart';

import 'package:vayu_drishti/main.dart';

void main() {
  testWidgets('VayuDrishti app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VayuDrishtiApp());

    // Verify that our app starts with splash screen.
    expect(find.text('VayuDrishti'), findsOneWidget);
  });
}
