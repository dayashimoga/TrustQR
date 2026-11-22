import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/src/state/admin_nav_controller.dart';

void main() {
  group('AdminNavController Unit Tests', () {
    test('initializes with default studio pane', () {
      final nav = AdminNavController();
      expect(nav.currentPane, equals(AdminPane.studio));
      expect(nav.currentIndex, equals(0));
    });

    test('initializes with custom initial pane', () {
      final nav = AdminNavController(initialPane: AdminPane.analytics);
      expect(nav.currentPane, equals(AdminPane.analytics));
      expect(nav.currentIndex, equals(2));
    });

    test('selectPane updates pane and notifies listeners', () {
      final nav = AdminNavController();
      var notifications = 0;
      nav.addListener(() => notifications++);

      nav.selectPane(AdminPane.batch);
      expect(nav.currentPane, equals(AdminPane.batch));
      expect(nav.currentIndex, equals(1));
      expect(notifications, equals(1));

      // Selecting same pane does not notify redundant event
      nav.selectPane(AdminPane.batch);
      expect(notifications, equals(1));
    });

    test('selectIndex maps indices correctly and ignores out-of-bounds', () {
      final nav = AdminNavController();
      nav.selectIndex(3);
      expect(nav.currentPane, equals(AdminPane.audit));
      expect(nav.currentIndex, equals(3));

      nav.selectIndex(4);
      expect(nav.currentPane, equals(AdminPane.settings));
      expect(nav.currentIndex, equals(4));

      // Out of bounds indices ignored
      nav.selectIndex(99);
      expect(nav.currentPane, equals(AdminPane.settings));

      nav.selectIndex(-1);
      expect(nav.currentPane, equals(AdminPane.settings));
    });
  });
}
