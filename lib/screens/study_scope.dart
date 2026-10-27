import 'package:flutter/material.dart';

import '../state/study_controller.dart';

class StudyScope extends InheritedNotifier<StudyController> {
  const StudyScope({
    super.key,
    required StudyController controller,
    required super.child,
  }) : super(notifier: controller);

  static StudyController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StudyScope>();
    assert(scope != null, 'StudyScope is missing above this widget.');
    return scope!.notifier!;
  }
}

class NavScope extends InheritedWidget {
  const NavScope({
    super.key,
    required this.goTo,
    required super.child,
  });

  final ValueChanged<int> goTo;

  static NavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavScope>();
  }

  @override
  bool updateShouldNotify(NavScope oldWidget) => goTo != oldWidget.goTo;
}
