import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/main.dart';
import 'package:ouroboros/states/player_state.dart';

void main() {
  Future<void> createCharacter(WidgetTester tester, {String name = 'Test Hero'}) async {
    // Scribe name
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();

    // Scroll button into view before tapping
    final commenceBtn = find.text('COMMENCE CHRONICLE');
    await tester.ensureVisible(commenceBtn);
    await tester.pumpAndSettle();
    await tester.tap(commenceBtn);
    await tester.pumpAndSettle();
  }

  testWidgets('Vitruvian Shadow App startup smoke test', (WidgetTester tester) async {
    // Reset state before building app to prevent GetX state leaks
    if (Get.isRegistered<PlayerState>()) {
      Get.find<PlayerState>().hasCreatedCharacter.value = false;
    }

    // Build our app and trigger a frame.
    await tester.pumpWidget(const VitruvianShadowApp());
    await tester.pumpAndSettle();

    // Clear intro screen
    await createCharacter(tester, name: 'Aleph');

    // Verify that the top title is shown.
    expect(find.text('VITRUVIAN SHADOW'), findsOneWidget);

    // Tap settings tab in BottomNavigationBar
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Verify settings elements are shown.
    expect(find.text('MASTER VOLUME'), findsOneWidget);
  });

  testWidgets('Vitruvian Shadow App character select and combat test', (WidgetTester tester) async {
    // Reset state before building app to prevent GetX state leaks
    if (Get.isRegistered<PlayerState>()) {
      Get.find<PlayerState>().hasCreatedCharacter.value = false;
    }

    await tester.pumpWidget(const VitruvianShadowApp());
    await tester.pumpAndSettle();

    // Clear intro screen
    await createCharacter(tester, name: 'Test Hero');

    // Ensure we are on the 'You' hub tab (clearing any leftover state from previous tests)
    await tester.tap(find.byIcon(Icons.portrait_outlined));
    await tester.pumpAndSettle();

    // Tap EQUIPPED tab via Tab widget type index
    await tester.tap(find.byType(Tab).at(0));
    await tester.pumpAndSettle();

    // Verify default active hero is the custom name
    expect(find.text('TEST HERO'), findsOneWidget);

    // Ensure Kaelen button is scrolled into view, then tap it
    final kaelenBtn = find.text('Kaelen');
    await tester.ensureVisible(kaelenBtn);
    await tester.pumpAndSettle();
    await tester.tap(kaelenBtn);
    await tester.pumpAndSettle();

    // Scroll back to top to verify name updated to KAELEN THE HERMETIC
    final kaelenName = find.text('KAELEN THE HERMETIC');
    await tester.ensureVisible(kaelenName);
    await tester.pumpAndSettle();
    expect(kaelenName, findsOneWidget);

    // Go to Game tab (middle tab)
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    // Scroll choice "Enter the breach" into view, then tap it
    final breachBtn = find.text('Enter the breach');
    await tester.ensureVisible(breachBtn);
    await tester.pumpAndSettle();
    await tester.tap(breachBtn);
    await tester.pumpAndSettle();

    // Verify we are now in the Combat Screen
    expect(find.text('YOUR TURN'), findsOneWidget);
    expect(find.text('PLAYER BACK LINE'), findsOneWidget);
    expect(find.text('PLAYER FRONT LINE'), findsOneWidget);
    expect(find.text('HP'), findsOneWidget);
    expect(find.text('STAM'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
  });
}
