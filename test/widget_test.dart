import 'dart:io';

import 'package:dart_project/data/study_repository.dart';
import 'package:dart_project/main.dart';
import 'package:dart_project/models/study_data.dart';
import 'package:dart_project/state/study_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StudyMate opens the sample dashboard', (tester) async {
    final controller = StudyController(
      StudyRepository(directory: Directory.systemTemp.createTempSync('usoum')),
    );
    await controller.init();
    await tester.pumpWidget(StudyMateApp(controller: controller));

    expect(find.text('Գլխավոր'), findsWidgets);
    expect(find.text('Վեկտորական տարածություն'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Խնդիրների փաթեթ 4'), 300);
    expect(find.text('Խնդիրների փաթեթ 4'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Միջանկյալ քննություն'), 300);
    expect(find.text('Միջանկյալ քննություն'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Գծային հանրահաշիվ'), findsWidgets);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Դասեր'), findsWidgets);

    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Լաբորատոր աշխատանքի սևագիր'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Միջինը ըստ կրեդիտների'), findsOneWidget);
    expect(find.text('Արված աշխատանք'), findsWidgets);
  });

  test('homework changes stay on device', () async {
    final directory = Directory.systemTemp.createTempSync('usoum');
    final repository = StudyRepository(directory: directory);
    final controller = StudyController(repository);
    await controller.init();
    final item = controller.homework.firstWhere((entry) => entry.id == 'hw-today');
    expect(item.done, isFalse);

    expect(await controller.setHomeworkStatus(item.id, TaskStatus.done), isNull);

    final reloaded = StudyController(StudyRepository(directory: directory));
    await reloaded.init();
    expect(
      reloaded.homework.firstWhere((entry) => entry.id == 'hw-today').done,
      isTrue,
    );
  });
}
