import 'package:flutter/material.dart';

class AppStateProvider extends InheritedWidget {
  final Locale locale;
  final Function(Locale) onLocaleChanged;

  const AppStateProvider({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  static AppStateProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
  }

  @override
  bool updateShouldNotify(AppStateProvider oldWidget) {
    return locale != oldWidget.locale;
  }

  bool get isArabic => locale.languageCode == 'ar';

  String t(String ar, String fr) => isArabic ? ar : fr;
}
