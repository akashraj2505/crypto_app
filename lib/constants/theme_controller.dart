import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Holds the user's colour preference and keeps it across app restarts.
class ThemeController extends ChangeNotifier {
  ThemeController([this._settings])
      : _mode = _settings?.get('theme_mode', defaultValue: 'dark') == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;

  final Box<dynamic>? _settings;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _settings?.put('theme_mode', mode.name);
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope is missing above this widget.');
    return scope!.notifier!;
  }
}
