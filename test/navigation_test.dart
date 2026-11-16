import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ouroboros/states/navigation_state.dart';

void main() {
  late NavigationState nav;

  setUp(() {
    Get.testMode = true;
    nav = Get.put(NavigationState());
  });
  tearDown(Get.reset);

  group('City districts', () {
    test('every district not marked locked in the data starts unlocked', () {
      for (final node in nav.nodes.values) {
        expect(nav.unlockedLocationIds.contains(node.id), !node.defaultLocked, reason: node.id);
      }
      // These two were wrongly locked before.
      expect(nav.unlockedLocationIds, containsAll(['n2', 'n3']));
      expect(nav.unlockedLocationIds, isNot(contains('market')));
    });

    test('entering a district remembers where you stand', () {
      nav.enterCity('aethel_cap');
      nav.moveToLocation('n3');
      expect(nav.currentMode.value, MapViewMode.location);
      expect(nav.presentLocationId.value, 'n3');

      nav.exitToCityStreets();
      expect(nav.currentMode.value, MapViewMode.city);
      expect(nav.presentLocationId.value, 'n3', reason: 'still standing in the vault');
      expect(nav.currentNode.id, 'n3');
    });

    test('the forge and bank sit on the High Street and are open', () {
      final city = nav.cities['aethel_cap']!;
      for (final id in ['forge', 'bank']) {
        expect(city.locationNodes, contains(id));
        expect(nav.nodes[id]!.connectedNodeIds, contains('market'), reason: id);
        expect(nav.nodes['market']!.connectedNodeIds, contains(id));
        expect(nav.unlockedLocationIds, contains(id));
      }
      expect(nav.nodes['forge']!.npcs, contains('Master Blacksmith'));
      expect(nav.nodes['market']!.npcs, isNot(contains('Master Blacksmith')));

      nav.enterCity('aethel_cap');
      expect(nav.moveToLocation('bank'), isNull);
      expect(nav.presentLocationId.value, 'bank');
    });

    test('the inn sits by the Shambles and is open', () {
      expect(nav.cities['aethel_cap']!.locationNodes, contains('inn'));
      expect(nav.nodes['inn']!.connectedNodeIds, containsAll(['slums', 'undercroft']));
      expect(nav.unlockedLocationIds, contains('inn'));
      expect(nav.nodes['inn']!.npcServices.values, containsAll([TownService.rest, TownService.drink]));

      nav.enterCity('aethel_cap');
      expect(nav.moveToLocation('inn'), isNull, reason: 'one step from the Undercroft');
      expect(nav.presentLocationId.value, 'inn');
    });

    test('district connections run both ways', () {
      for (final n in nav.nodes.values) {
        for (final t in n.connectedNodeIds) {
          expect(nav.nodes[t]!.connectedNodeIds, contains(n.id), reason: '${n.id} -> $t');
        }
      }
    });

    test('a locked district can\'t be entered', () {
      nav.enterCity('aethel_cap');
      nav.moveToLocation('market');
      expect(nav.currentMode.value, MapViewMode.city);
      expect(nav.presentLocationId.value, 'undercroft');
    });
  });

  group('World travel', () {
    test('you can only enter the streets of the city you are in', () {
      expect(nav.enterCity('riverend_port'), 'Travel there first.');
      expect(nav.enterCity('sylvanis'), isNotNull, reason: 'locked');
      expect(nav.enterCity('aethel_cap'), isNull);
      expect(nav.currentMode.value, MapViewMode.city);
    });

    test('uncharted cities say so instead of opening', () {
      nav.selectWorldCity('frost_keep');
      expect(nav.travelToSelectedCity(), ['frost_keep']);
      expect(nav.enterCity('frost_keep'), 'Its streets have not been charted yet.');
      expect(nav.currentMode.value, MapViewMode.overworld);
    });

    test('travel follows the shortest route through unlocked cities', () {
      // Bowerstone -> Riverend -> Island of Skulls
      expect(nav.routeTo('island_of_skulls'), ['riverend_port', 'island_of_skulls']);
      expect(nav.routeTo('sylvanis'), isEmpty, reason: 'locked');

      nav.unlockCity('gilded_shore');
      nav.unlockCity('sylvanis');
      expect(nav.routeTo('sylvanis'), ['riverend_port', 'gilded_shore', 'sylvanis']);

      nav.selectWorldCity('sylvanis');
      expect(nav.travelToSelectedCity(), ['riverend_port', 'gilded_shore', 'sylvanis']);
      expect(nav.currentWorldCityId.value, 'sylvanis');
    });

    test('the app bar title follows the map view', () {
      expect(nav.mapTitle, 'The Known World');
      nav.enterCity('aethel_cap');
      expect(nav.mapTitle, nav.cities['aethel_cap']!.name);
      nav.moveToLocation('n1');
      expect(nav.mapTitle, 'Vichally Amphitheater Scriptorium');
    });
  });
}
