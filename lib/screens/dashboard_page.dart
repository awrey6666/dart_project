import 'package:flutter/material.dart';

import '../models/study_data.dart';
import '../state/study_controller.dart';
import '../util/format.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final lessons = controller.lessonsOn(DateTime.now());
    final tasks = controller.openHomework.take(3).toList();
    final exams = controller.upcomingExams.take(3).toList();
    final average = controller.overallAverage;
    final openCount = controller.openHomework.length;
    final examCount = controller.upcomingExams.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Այստեղ երևում են այսօրվա դասերը, չարված աշխատանքները և մոտակա քննությունները։',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final tiles = [
              StatTile(
                label: 'Միջին գնահատական',
                value: formatPercent(average),
                icon: Icons.school_outlined,
              ),
              StatTile(
                label: 'Չարված աշխատանք',
                value: '$openCount',
                icon: Icons.assignment_outlined,
              ),
              StatTile(
                label: 'Մոտակա քննություն',
                value: '$examCount',
                icon: Icons.event_note_outlined,
              ),
            ];
            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  for (final tile in tiles) ...[tile, const SizedBox(height: 8)],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Այսօրվա դասերը',
          action: TextButton(
            onPressed: () => NavScope.maybeOf(context)?.goTo(2),
            child: const Text('Օրացույց'),
          ),
        ),
        if (lessons.isEmpty)
          const EmptyHint(
            icon: Icons.menu_book_outlined,
            message: 'Այսօր դաս չկա։ Դաս ավելացրեք օրացույցից կամ առարկայի էջից։',
          )
        else
          for (final lesson in lessons) ...[
            _ClassCard(controller: controller, lesson: lesson),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Ինչ պետք է անել',
          action: TextButton(
            onPressed: () => NavScope.maybeOf(context)?.goTo(3),
            child: const Text('Աշխատանք'),
          ),
        ),
        if (tasks.isEmpty)
          const EmptyHint(
            icon: Icons.assignment_turned_in_outlined,
            message: 'Չարված աշխատանք չկա։ Նորը կերևա այստեղ։',
          )
        else
          for (final item in tasks) ...[
            _HomeworkCard(controller: controller, item: item),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Քննություններ',
          action: TextButton(
            onPressed: () => NavScope.maybeOf(context)?.goTo(2),
            child: const Text('Օրացույց'),
          ),
        ),
        if (exams.isEmpty)
          const EmptyHint(
            icon: Icons.event_available_outlined,
            message: 'Մոտակա քննություն չկա։',
          )
        else
          for (final item in exams) ...[
            _ExamCard(controller: controller, item: item),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.controller, required this.lesson});

  final StudyController controller;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final subject = controller.subjectById(lesson.subjectId);
    final place = [
      if (subject != null && subject.teacher.isNotEmpty) subject.teacher,
      if (subject != null && subject.room.isNotEmpty) subject.room,
      lesson.summary,
    ].where((part) => part.isNotEmpty).join(' · ');
    return StudyTile(
      color: subject?.color ?? Theme.of(context).colorScheme.primary,
      title: lesson.title,
      subtitle: [subject?.name ?? 'Առարկա', place].where((part) => part.isNotEmpty).join('\n'),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.controller, required this.item});

  final StudyController controller;
  final HomeworkItem item;

  @override
  Widget build(BuildContext context) {
    final subject = controller.subjectById(item.subjectId);
    final overdue = dateOnly(item.due).isBefore(dateOnly(DateTime.now()));
    return StudyTile(
      color: subject?.color ?? Theme.of(context).colorScheme.primary,
      title: item.title,
      subtitle:
          '${subject?.name ?? 'Առարկա'} · ${dueLabel(item.due)}',
      trailing: overdue
          ? Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error)
          : null,
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.controller, required this.item});

  final StudyController controller;
  final ExamItem item;

  @override
  Widget build(BuildContext context) {
    final subject = controller.subjectById(item.subjectId);
    return StudyTile(
      color: subject?.color ?? Theme.of(context).colorScheme.primary,
      title: item.title,
      subtitle: [
        subject?.name ?? 'Առարկա',
        formatDayTime(item.when),
        item.location,
      ].where((part) => part.isNotEmpty).join(' · '),
    );
  }
}
