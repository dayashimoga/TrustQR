import 'package:flutter/foundation.dart';

/// Navigation panes supported by the Admin Application.
enum AdminPane {
  studio,
  batch,
  analytics,
  audit,
  settings,
}

/// Navigation coordinator for switching between Admin App workspaces.
class AdminNavController extends ChangeNotifier {
  AdminPane _currentPane;

  AdminNavController({AdminPane initialPane = AdminPane.studio})
      : _currentPane = initialPane;

  AdminPane get currentPane => _currentPane;
  int get currentIndex => _currentPane.index;

  void selectPane(AdminPane pane) {
    if (_currentPane != pane) {
      _currentPane = pane;
      notifyListeners();
    }
  }

  void selectIndex(int index) {
    if (index >= 0 && index < AdminPane.values.length) {
      selectPane(AdminPane.values[index]);
    }
  }
}
