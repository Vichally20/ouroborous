import 'package:flutter_test/flutter_test.dart';
import 'package:ouroboros/main.dart';

void main() {
  testWidgets('Vitruvian Shadow App startup smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VitruvianShadowApp());

    // Verify that the top title and Settings elements are shown.
    expect(find.text('VITRUVIAN SHADOW'), findsOneWidget);
    expect(find.text('MASTER VOLUME'), findsOneWidget);
  });
}
