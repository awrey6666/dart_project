import 'package:flutter/material.dart';

import '../logic/academics.dart';
import '../models/study_data.dart';
import '../state/study_controller.dart';
import '../util/format.dart';
import '../widgets/editors.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';

enum _DetailSection { overview, lessons, notes, homework, exams, grades, resources }

class SubjectDetailPage extends StatefulWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  var _section = _DetailSection.overview;

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final subject = controller.subjectById(widget.subjectId);
    if (subject == null) {
      return const Scaffold(body: Center(child: Text('Այս առարկան ջնջված է։')));
    }
    final average = controller.averageFor(subject.id);
    final tasks = controller.homeworkFor(subject.id);
    final done = tasks.where((item) => item.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
            tooltip: 'Խմբագրել առարկան',
            onPressed: () => _editSubject(subject),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      floatingActionButton: _section == _DetailSection.overview
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(controller, subject.id),
              icon: const Icon(Icons.add),
              label: Text(_addLabel),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            [
              if (subject.teacher.isNotEmpty) subject.teacher,
              if (subject.room.isNotEmpty) subject.room,
              '${_credits(subject.credits)} կրեդիտ',
            ].join(' · '),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final section in _DetailSection.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_sectionLabel(section)),
                      selected: _section == section,
                      onSelected: (_) => setState(() => _section = section),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_section == _DetailSection.overview) ...[
            StatTile(
              label: 'Առարկայի միջինը',
              value: formatPercent(average),
              icon: Icons.insights_outlined,
            ),
            const SizedBox(height: 8),
            StatTile(
              label: 'Արված աշխատանք',
              value: tasks.isEmpty ? '—' : '$done/${tasks.length}',
              icon: Icons.assignment_turned_in_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              average == null
                  ? 'Գրեք գնահատական, որպեսզի այս առարկայի միջինը հաշվվի։'
                  : 'Տառ ${Academics.letter(average)}։ Հաշվի է առնվում յուրաքանչյուր գնահատականի կարևորությունը։',
            ),
          ],
          if (_section == _DetailSection.lessons)
            _recordList(
              items: controller.lessonsFor(subject.id),
              empty: 'Ավելացրեք այս առարկայի դասը։',
              title: (lesson) => lesson.title,
              subtitle: (lesson) => [formatDay(lesson.date), lesson.summary].where((part) => part.isNotEmpty).join('\n'),
              color: subject.color,
              onEdit: (lesson) => _editLesson(subject.id, lesson),
              onDelete: (lesson) => _remove('Ջնջե՞լ այս դասը', lesson.title, () => controller.deleteLesson(lesson.id)),
            ),
          if (_section == _DetailSection.notes)
            _recordList(
              items: controller.notesFor(subject.id),
              empty: 'Գրեք նշում, որը ուզում եք պահել այս առարկայի մոտ։',
              title: (note) => note.title,
              subtitle: (note) => note.body,
              color: subject.color,
              onEdit: (note) => _editNote(subject.id, note),
              onDelete: (note) => _remove('Ջնջե՞լ այս նշումը', note.title, () => controller.deleteNote(note.id)),
            ),
          if (_section == _DetailSection.homework)
            _recordList(
              items: controller.homeworkFor(subject.id),
              empty: 'Այս առարկայի աշխատանք չկա։',
              title: (item) => item.title,
              subtitle: (item) => '${dueLabel(item.due)}\n${priorityLabel(item.priority)} · ${statusLabel(item.status)}',
              color: subject.color,
              onEdit: (item) => _editHomework(item),
              onDelete: (item) => _remove('Ջնջե՞լ այս աշխատանքը', item.title, () => controller.deleteHomework(item.id)),
            ),
          if (_section == _DetailSection.exams)
            _recordList(
              items: controller.examsFor(subject.id),
              empty: 'Այս առարկայի քննություն չկա։',
              title: (exam) => exam.title,
              subtitle: (exam) => [formatDayTime(exam.when), exam.location, exam.notes].where((part) => part.isNotEmpty).join('\n'),
              color: subject.color,
              onEdit: (exam) => _editExam(exam),
              onDelete: (exam) => _remove('Ջնջե՞լ այս քննությունը', exam.title, () => controller.deleteExam(exam.id)),
            ),
          if (_section == _DetailSection.grades)
            _recordList(
              items: controller.gradesFor(subject.id),
              empty: 'Ավելացրեք գնահատական, որպեսզի այն մտնի միջինի մեջ։',
              title: (grade) => grade.title,
              subtitle: (grade) => '${grade.score}/${grade.maxScore} · ${formatPercent(grade.percent)} · կարևորություն ${grade.weight}',
              color: subject.color,
              onEdit: (grade) => _editGrade(grade),
              onDelete: (grade) => _remove('Ջնջե՞լ այս գնահատականը', grade.title, () => controller.deleteGrade(grade.id)),
            ),
          if (_section == _DetailSection.resources)
            _recordList(
              items: controller.resourcesFor(subject.id),
              empty: 'Ավելացրեք դասագիրք, հղում կամ այլ աղբյուր։',
              title: (resource) => resource.title,
              subtitle: (resource) => resource.detail,
              color: subject.color,
              onEdit: (resource) => _editResource(subject.id, resource),
              onDelete: (resource) => _remove('Ջնջե՞լ այս աղբյուրը', resource.title, () => controller.deleteResource(resource.id)),
            ),
        ],
      ),
    );
  }

  String get _addLabel => switch (_section) {
    _DetailSection.lessons => 'Դաս',
    _DetailSection.notes => 'Նշում',
    _DetailSection.homework => 'Աշխատանք',
    _DetailSection.exams => 'Քննություն',
    _DetailSection.grades => 'Գնահատական',
    _DetailSection.resources => 'Աղբյուր',
    _DetailSection.overview => '',
  };

  String _sectionLabel(_DetailSection section) => switch (section) {
    _DetailSection.overview => 'Առաջընթաց',
    _DetailSection.lessons => 'Դասեր',
    _DetailSection.notes => 'Նշումներ',
    _DetailSection.homework => 'Աշխատանք',
    _DetailSection.exams => 'Քննություններ',
    _DetailSection.grades => 'Գնահատականներ',
    _DetailSection.resources => 'Աղբյուրներ',
  };

  String _credits(double credits) {
    return credits == credits.roundToDouble() ? credits.toStringAsFixed(0) : credits.toString();
  }

  Widget _recordList<T>({
    required List<T> items,
    required String empty,
    required String Function(T item) title,
    required String Function(T item) subtitle,
    required Color color,
    required void Function(T item) onEdit,
    required void Function(T item) onDelete,
  }) {
    if (items.isEmpty) return EmptyHint(icon: Icons.inbox_outlined, message: empty);
    return Column(
      children: [
        for (final item in items) ...[
          StudyTile(
            color: color,
            title: title(item),
            subtitle: subtitle(item).isEmpty ? ' ' : subtitle(item),
            onTap: () => onEdit(item),
            trailing: ItemMenu(onEdit: () => onEdit(item), onDelete: () => onDelete(item)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _add(StudyController controller, String subjectId) async {
    switch (_section) {
      case _DetailSection.lessons:
        await _editLesson(subjectId, null);
      case _DetailSection.notes:
        await _editNote(subjectId, null);
      case _DetailSection.homework:
        await _editHomework(null);
      case _DetailSection.exams:
        await _editExam(null);
      case _DetailSection.grades:
        await _editGrade(null);
      case _DetailSection.resources:
        await _editResource(subjectId, null);
      case _DetailSection.overview:
        break;
    }
  }

  Future<void> _editSubject(Subject subject) async {
    final updated = await showSubjectEditor(context, existing: subject);
    if (updated == null || !mounted) return;
    final message = await StudyScope.of(context).saveSubject(updated);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editLesson(String subjectId, Lesson? existing) async {
    final lesson = await showLessonEditor(context, subjectId: subjectId, existing: existing);
    if (lesson == null || !mounted) return;
    final message = await StudyScope.of(context).saveLesson(lesson);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editNote(String subjectId, StudyNote? existing) async {
    final note = await showNoteEditor(context, subjectId: subjectId, existing: existing);
    if (note == null || !mounted) return;
    final message = await StudyScope.of(context).saveNote(note);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editResource(String subjectId, StudyResource? existing) async {
    final resource = await showResourceEditor(context, subjectId: subjectId, existing: existing);
    if (resource == null || !mounted) return;
    final message = await StudyScope.of(context).saveResource(resource);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editHomework(HomeworkItem? existing) async {
    final controller = StudyScope.of(context);
    final item = await showHomeworkEditor(
      context,
      subjects: controller.subjects.where((subject) => subject.id == widget.subjectId).toList(),
      existing: existing,
    );
    if (item == null || !mounted) return;
    final message = await StudyScope.of(context).saveHomework(item);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editExam(ExamItem? existing) async {
    final controller = StudyScope.of(context);
    final exam = await showExamEditor(
      context,
      subjects: controller.subjects.where((subject) => subject.id == widget.subjectId).toList(),
      existing: existing,
    );
    if (exam == null || !mounted) return;
    final message = await StudyScope.of(context).saveExam(exam);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _editGrade(GradeItem? existing) async {
    final controller = StudyScope.of(context);
    final grade = await showGradeEditor(
      context,
      subjects: controller.subjects.where((subject) => subject.id == widget.subjectId).toList(),
      existing: existing,
    );
    if (grade == null || !mounted) return;
    final message = await StudyScope.of(context).saveGrade(grade);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _remove(String title, String name, Future<String?> Function() action) async {
    final confirmed = await confirmDelete(context, title: title, message: '«$name» կջնջվի։');
    if (!confirmed || !mounted) return;
    final message = await action();
    if (!mounted) return;
    showStudyMessage(context, message);
  }
}
