import 'package:flutter/material.dart';

import 'learn_controller.dart';

class LearnScope extends InheritedNotifier<LearnController> {
  const LearnScope({
    super.key,
    required LearnController controller,
    required super.child,
  }) : super(notifier: controller);

  static LearnController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LearnScope>();
    assert(scope != null, 'LearnScope is missing above this widget.');
    return scope!.notifier!;
  }
}
