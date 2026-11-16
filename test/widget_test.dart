import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/game/story_engine.dart';
import 'package:ouroboros/main.dart';
import 'package:ouroboros/ui/menu/vector_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    VectorBackdrop.animated = false;
    SharedPreferences.setMockInitialValues({});
    // A cached asset future from the previous test's fake-time zone never completes here.
    rootBundle.clear();
  });
  tearDown(Get.reset);

  Future<void> createCharacter(WidgetTester tester, {String name = 'Test Hero'}) async {
    // Main menu: start a new game
    expect(find.text('CONTINUE'), findsOneWidget);
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE THY LIKENESS'), findsOneWidget);

    // Scribe name
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();

    // Scroll button into view before tapping
    final commenceBtn = find.text('COMMENCE CHRONICLE');
    await tester.ensureVisible(commenceBtn);
    await tester.pumpAndSettle();
    await tester.tap(commenceBtn);
    // The new session loads chapter 1 from assets with real I/O; give it real time.
    for (var i = 0; i < 20 && Get.find<StoryEngine>().isLoading.value; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Vitruvian Shadow App startup smoke test', (WidgetTester tester) async {
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

    // Saving shows one compact toast, at most 380 wide and short.
    final saveBtn = find.text('SAVE GAME');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final toast = find.text('CHRONICLE SAVED');
    expect(toast, findsOneWidget);
    final card = find.ancestor(of: toast, matching: find.byType(DecoratedBox)).first;
    final size = tester.getSize(card);
    expect(size.width, lessThanOrEqualTo(380));
    expect(size.height, lessThan(90));

    // A second toast replaces the first instead of stacking under it.
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('CHRONICLE SAVED'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('CHRONICLE SAVED'), findsNothing, reason: 'gone after its time');
  });

  testWidgets('Vitruvian Shadow App character select and combat test', (WidgetTester tester) async {
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

    // A new game opens in Act I; this test fights the Undercroft encounter, so load that chapter.
    await tester.runAsync(() => Get.find<StoryEngine>().loadChapter('chapter_1'));
    await tester.pumpAndSettle();

    // Go to Game tab (middle tab)
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    // Scroll choice "Enter the breach" into view, then tap it
    final breachBtn = find.text('Enter the breach');
    await tester.ensureVisible(breachBtn);
    await tester.pumpAndSettle();
    await tester.tap(breachBtn);
    await tester.pumpAndSettle();

    // Verify we are now in the Combat Screen, which owns the whole screen
    expect(find.textContaining('YOUR TURN'), findsOneWidget);
    expect(find.text('YOUR BACK LINE'), findsOneWidget);
    expect(find.text('YOUR FRONT LINE'), findsOneWidget);
    expect(find.text('HP'), findsOneWidget);
    expect(find.text('STA'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    expect(find.byTooltip('Flee'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing, reason: 'bottom nav hidden during combat');

    // The hand shows Strike and Defend; the empty front line offers a move.
    expect(find.text('Standard Strike'), findsOneWidget);
    expect(find.text('Defend'), findsOneWidget);
    expect(find.text('STEP FORWARD'), findsOneWidget);

    // Ready Strike, then cast it on the selected enemy by tapping the card again.
    await tester.tap(find.text('Standard Strike'));
    await tester.pump();
    expect(find.textContaining('Tap again'), findsOneWidget);
  });
}
