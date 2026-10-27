import 'package:flutter/material.dart';

import '../models/study_data.dart';
import '../state/study_controller.dart';
import '../util/format.dart';
import '../widgets/editors.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth = dateOnly(DateTime(DateTime.now().year, DateTime.now().month));
  late DateTime _selected = dateOnly(DateTime.now());

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final days = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday - 1;
    final lessons = controller.lessonsOn(_selected);
    final exams = controller.examsOn(_selected);
    final tasks = controller.homeworkOn(_selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Նախորդ ամիս',
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                formatMonth(_visibleMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Հաջորդ ամիս',
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final name in weekdayShort)
              Expanded(
                child: Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 6; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _DayCell(
                    day: row * 7 + column - leading + 1,
                    daysInMonth: days,
                    month: _visibleMonth,
                    selected: _selected,
                    hasEvents: (date) =>
                        controller.lessonsOn(date).isNotEmpty ||
                        controller.examsOn(date).isNotEmpty ||
                        controller.homeworkOn(date).isNotEmpty,
                    onSelect: (date) => setState(() => _selected = date),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Text(formatDay(_selected), style: Theme.of(context).textTheme.titleMedium),
        Text(
          'Ընտրեք օրը։ Ներքևում երևում են այդ օրվա դասերը, քննությունները և վերջնաժամկետները։',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Դասեր'),
        if (lessons.isEmpty)
          const EmptyHint(icon: Icons.menu_book_outlined, message: 'Այս օրը դաս չկա։')
        else
          for (final lesson in lessons) ...[
            _AgendaTile(
              color: controller.subjectById(lesson.subjectId)?.color ?? scheme.primary,
              title: lesson.title,
              subtitle: _subjectLine(controller, lesson.subjectId, lesson.summary),
            ),
            const SizedBox(height: 8),
          ],
        const SectionHeader(title: 'Քննություններ'),
        if (exams.isEmpty)
          const EmptyHint(icon: Icons.event_available_outlined, message: 'Այս օրը քննություն չկա։')
        else
          for (final exam in exams) ...[
            _AgendaTile(
              color: controller.subjectById(exam.subjectId)?.color ?? scheme.primary,
              title: exam.title,
              subtitle: _subjectLine(controller, exam.subjectId, exam.location),
            ),
            const SizedBox(height: 8),
          ],
        const SectionHeader(title: 'Վերջնաժամկետներ'),
        if (tasks.isEmpty)
          const EmptyHint(icon: Icons.assignment_outlined, message: 'Այս օրը վերջնաժամկետ չկա։')
        else
          for (final task in tasks) ...[
            _AgendaTile(
              color: controller.subjectById(task.subjectId)?.color ?? scheme.primary,
              title: task.title,
              subtitle: _subjectLine(
                controller,
                task.subjectId,
                '${priorityLabel(task.priority)} · ${statusLabel(task.status)}',
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: controller.subjects.isEmpty
                  ? null
                  : () => _addLesson(controller),
              icon: const Icon(Icons.add),
              label: const Text('Դաս'),
            ),
            FilledButton.tonalIcon(
              onPressed: controller.subjects.isEmpty
                  ? null
                  : () => _addExam(),
              icon: const Icon(Icons.add),
              label: const Text('Քննություն'),
            ),
            FilledButton.tonalIcon(
              onPressed: controller.subjects.isEmpty
                  ? null
                  : () => _addHomework(),
              icon: const Icon(Icons.add),
              label: const Text('Աշխատանք'),
            ),
          ],
        ),
      ],
    );
  }

  String _subjectLine(StudyController controller, String subjectId, String extra) {
    final subject = controller.subjectById(subjectId);
    final place = [
      if (subject != null && subject.teacher.isNotEmpty) subject.teacher,
      if (subject != null && subject.room.isNotEmpty) subject.room,
      if (extra.isNotEmpty) extra,
    ].join(' · ');
    return [subject?.name ?? 'Առարկա', place].where((part) => part.isNotEmpty).join('\n');
  }

  Future<void> _addLesson(StudyController controller) async {
    final subjectId = await _pickSubject();
    if (subjectId == null || !mounted) return;
    final lesson = await showLessonEditor(context, subjectId: subjectId, date: _selected);
    if (lesson == null || !mounted) return;
    final message = await controller.saveLesson(lesson);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _addExam() async {
    final subjectId = await _pickSubject();
    if (subjectId == null || !mounted) return;
    final subjects = StudyScope.of(context).subjects;
    final exam = await showExamEditor(context, subjects: subjects);
    if (exam == null || !mounted) return;
    final dated = ExamItem(
      id: exam.id,
      subjectId: subjectId,
      title: exam.title,
      when: DateTime(_selected.year, _selected.month, _selected.day, exam.when.hour, exam.when.minute),
      location: exam.location,
      notes: exam.notes,
    );
    final message = await StudyScope.of(context).saveExam(dated);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _addHomework() async {
    final item = await showHomeworkEditor(
      context,
      subjects: StudyScope.of(context).subjects,
      due: _selected,
    );
    if (item == null || !mounted) return;
    final message = await StudyScope.of(context).saveHomework(item);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<String?> _pickSubject() async {
    final subjects = StudyScope.of(context).subjects;
    if (subjects.isEmpty) {
      showStudyMessage(context, 'Նախ ավելացրեք առարկա։');
      return null;
    }
    if (subjects.length == 1) return subjects.first.id;
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ո՞ր առարկան'),
        children: [
          for (final subject in subjects)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, subject.id),
              child: Text(subject.name),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.daysInMonth,
    required this.month,
    required this.selected,
    required this.hasEvents,
    required this.onSelect,
  });

  final int day;
  final int daysInMonth;
  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime date) hasEvents;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);
    final date = DateTime(month.year, month.month, day);
    final isSelected = sameDay(date, selected);
    final isToday = sameDay(date, DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onSelect(date),
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : null,
                shape: BoxShape.circle,
                border: isToday && !isSelected ? Border.all(color: scheme.primary) : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(color: isSelected ? scheme.onPrimary : null),
              ),
            ),
            if (hasEvents(date))
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: scheme.tertiary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.color, required this.title, required this.subtitle});

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudyTile(color: color, title: title, subtitle: subtitle);
  }
}
