import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/study_data.dart';
import '../util/format.dart';

Future<Subject?> showSubjectEditor(
  BuildContext context, {
  Subject? existing,
}) {
  return showDialog<Subject>(
    context: context,
    builder: (context) => _SubjectDialog(existing: existing),
  );
}

class _SubjectDialog extends StatefulWidget {
  const _SubjectDialog({this.existing});

  final Subject? existing;

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  late final TextEditingController _name;
  late final TextEditingController _teacher;
  late final TextEditingController _room;
  late final TextEditingController _credits;
  late int _color;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _teacher = TextEditingController(text: existing?.teacher ?? '');
    _room = TextEditingController(text: existing?.room ?? '');
    _credits = TextEditingController(
      text: (existing?.credits ?? 3).toStringAsFixed(
        existing?.credits == existing?.credits.roundToDouble() ? 0 : 1,
      ),
    );
    _color = existing?.colorValue ?? subjectPalette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _room.dispose();
    _credits.dispose();
    super.dispose();
  }

  void _save() {
    final credits = double.tryParse(_credits.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      Subject(
        id: widget.existing?.id ?? createId(),
        name: _name.text.trim(),
        teacher: _teacher.text.trim(),
        room: _room.text.trim(),
        colorValue: _color,
        credits: credits < 0 ? 0 : credits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialog(
      title: widget.existing == null ? 'Նոր առարկա' : 'Խմբագրել առարկան',
      onSave: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Առարկայի անուն',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teacher,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Դասախոս'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _room,
            decoration: const InputDecoration(labelText: 'Լսարան'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _credits,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Կրեդիտ',
              helperText: 'Որքան մեծ է թիվը, այնքան առարկան ավելի է ազդում ընդհանուր միջինի վրա։',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Գույն',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final color in subjectPalette)
                InkWell(
                  onTap: () => setState(() => _color = color),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(color),
                    child: _color == color
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


Future<HomeworkItem?> showHomeworkEditor(
  BuildContext context, {
  required List<Subject> subjects,
  HomeworkItem? existing,
  DateTime? due,
}) {
  if (subjects.isEmpty) return Future.value();
  return showDialog<HomeworkItem>(
    context: context,
    builder: (context) => _HomeworkDialog(
      subjects: subjects,
      existing: existing,
      due: due,
    ),
  );
}

class _HomeworkDialog extends StatefulWidget {
  const _HomeworkDialog({required this.subjects, this.existing, this.due});

  final List<Subject> subjects;
  final HomeworkItem? existing;
  final DateTime? due;

  @override
  State<_HomeworkDialog> createState() => _HomeworkDialogState();
}

class _HomeworkDialogState extends State<_HomeworkDialog> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late String _subjectId;
  late DateTime _due;
  late TaskPriority _priority;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _subjectId = existing?.subjectId ?? widget.subjects.first.id;
    _due = existing?.due ?? widget.due ?? dateOnly(DateTime.now()).add(const Duration(days: 1));
    _priority = existing?.priority ?? TaskPriority.medium;
    _status = existing?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialog(
      title: widget.existing == null ? 'Նոր աշխատանք' : 'Խմբագրել աշխատանքը',
      onSave: () {
        Navigator.pop(
          context,
          HomeworkItem(
            id: widget.existing?.id ?? createId(),
            subjectId: _subjectId,
            title: _title.text.trim(),
            notes: _notes.text.trim(),
            due: dateOnly(_due),
            priority: _priority,
            status: _status,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Վերնագիր'),
          ),
          const SizedBox(height: 12),
          _SubjectDropdown(
            subjects: widget.subjects,
            value: _subjectId,
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Վերջնաժամկետ'),
            subtitle: Text(formatDay(_due)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _due,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null && context.mounted) setState(() => _due = picked);
            },
          ),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Որքան շտապ է',
              helperText: 'Բարձրը ավելի շտապ է։',
            ),
            items: [
              for (final priority in TaskPriority.values)
                DropdownMenuItem(value: priority, child: Text(priorityLabel(priority))),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskStatus>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Ինչ վիճակում է',
              helperText: 'Անելիք, ընթացքում կամ արված։',
            ),
            items: [
              for (final status in TaskStatus.values)
                DropdownMenuItem(value: status, child: Text(statusLabel(status))),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Նշում'),
          ),
        ],
      ),
    );
  }
}

Future<ExamItem?> showExamEditor(
  BuildContext context, {
  required List<Subject> subjects,
  ExamItem? existing,
}) {
  if (subjects.isEmpty) return Future.value();
  return showDialog<ExamItem>(
    context: context,
    builder: (context) => _ExamDialog(subjects: subjects, existing: existing),
  );
}

class _ExamDialog extends StatefulWidget {
  const _ExamDialog({required this.subjects, this.existing});

  final List<Subject> subjects;
  final ExamItem? existing;

  @override
  State<_ExamDialog> createState() => _ExamDialogState();
}

class _ExamDialogState extends State<_ExamDialog> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late String _subjectId;
  late DateTime _when;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _subjectId = existing?.subjectId ?? widget.subjects.first.id;
    _when = existing?.when ?? dateOnly(DateTime.now()).add(const Duration(days: 7, hours: 9));
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialog(
      title: widget.existing == null ? 'Նոր քննություն' : 'Խմբագրել քննությունը',
      onSave: () {
        Navigator.pop(
          context,
          ExamItem(
            id: widget.existing?.id ?? createId(),
            subjectId: _subjectId,
            title: _title.text.trim(),
            when: _when,
            location: _location.text.trim(),
            notes: _notes.text.trim(),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Քննության անուն'),
          ),
          const SizedBox(height: 12),
          _SubjectDropdown(
            subjects: widget.subjects,
            value: _subjectId,
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Օր և ժամ'),
            subtitle: Text(formatDayTime(_when)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _when,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date == null) return;
              if (!context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_when),
              );
              if (!context.mounted || time == null) return;
              setState(() {
                _when = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            },
          ),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Վայր'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Նշում'),
          ),
        ],
      ),
    );
  }
}

Future<GradeItem?> showGradeEditor(
  BuildContext context, {
  required List<Subject> subjects,
  GradeItem? existing,
}) {
  if (subjects.isEmpty) return Future.value();
  return showDialog<GradeItem>(
    context: context,
    builder: (context) => _GradeDialog(subjects: subjects, existing: existing),
  );
}

class _GradeDialog extends StatefulWidget {
  const _GradeDialog({required this.subjects, this.existing});

  final List<Subject> subjects;
  final GradeItem? existing;

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late final TextEditingController _title;
  late final TextEditingController _score;
  late final TextEditingController _max;
  late final TextEditingController _weight;
  late String _subjectId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _score = TextEditingController(text: existing == null ? '' : _num(existing.score));
    _max = TextEditingController(text: existing == null ? '100' : _num(existing.maxScore));
    _weight = TextEditingController(text: existing == null ? '1' : _num(existing.weight));
    _subjectId = existing?.subjectId ?? widget.subjects.first.id;
    _date = existing?.date ?? dateOnly(DateTime.now());
  }

  String _num(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _score.dispose();
    _max.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialog(
      title: widget.existing == null ? 'Նոր գնահատական' : 'Խմբագրել գնահատականը',
      onSave: () {
        Navigator.pop(
          context,
          GradeItem(
            id: widget.existing?.id ?? createId(),
            subjectId: _subjectId,
            title: _title.text.trim(),
            score: double.tryParse(_score.text.trim()) ?? -1,
            maxScore: double.tryParse(_max.text.trim()) ?? 0,
            weight: double.tryParse(_weight.text.trim()) ?? 0,
            date: dateOnly(_date),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ինչի համար է',
              helperText: 'Օրինակ՝ ստուգողական, լաբորատոր, շարադրություն։',
            ),
          ),
          const SizedBox(height: 12),
          _SubjectDropdown(
            subjects: widget.subjects,
            value: _subjectId,
            onChanged: (value) => setState(() => _subjectId = value),
          ),
          const SizedBox(height: 12),
          _NumberField(controller: _score, label: 'Ստացած միավոր'),
          const SizedBox(height: 12),
          _NumberField(controller: _max, label: 'Առավելագույն միավոր'),
          const SizedBox(height: 12),
          _NumberField(
            controller: _weight,
            label: 'Կարևորություն',
            helper: 'Որքան մեծ է, այնքան ավելի է ազդում առարկայի միջինի վրա։',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Օր'),
            subtitle: Text(formatDay(_date)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.helper});

  final TextEditingController controller;
  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(labelText: label, helperText: helper),
    );
  }
}

class _SubjectDropdown extends StatelessWidget {
  const _SubjectDropdown({
    required this.subjects,
    required this.value,
    required this.onChanged,
  });

  final List<Subject> subjects;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Առարկա'),
      items: [
        for (final subject in subjects)
          DropdownMenuItem(value: subject.id, child: Text(subject.name)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _EditorDialog extends StatelessWidget {
  const _EditorDialog({
    required this.title,
    required this.child,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: child)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Չեղարկել'),
        ),
        FilledButton(onPressed: onSave, child: const Text('Պահել')),
      ],
    );
  }
}

Future<Lesson?> showLessonEditor(
  BuildContext context, {
  required String subjectId,
  Lesson? existing,
  DateTime? date,
}) {
  return showDialog<Lesson>(
    context: context,
    builder: (context) => _TextRecordDialog<Lesson>(
      title: existing == null ? 'Նոր դաս' : 'Խմբագրել դասը',
      firstLabel: 'Դասի թեմա',
      secondLabel: 'Ինչ անցաք',
      first: existing?.title ?? '',
      second: existing?.summary ?? '',
      date: existing?.date ?? date ?? dateOnly(DateTime.now()),
      onSave: (title, body, when) => Lesson(
        id: existing?.id ?? createId(),
        subjectId: subjectId,
        title: title,
        date: when,
        summary: body,
      ),
    ),
  );
}

Future<StudyNote?> showNoteEditor(
  BuildContext context, {
  required String subjectId,
  StudyNote? existing,
}) {
  return showDialog<StudyNote>(
    context: context,
    builder: (context) => _TextRecordDialog<StudyNote>(
      title: existing == null ? 'Նոր նշում' : 'Խմբագրել նշումը',
      firstLabel: 'Վերնագիր',
      secondLabel: 'Տեքստ',
      first: existing?.title ?? '',
      second: existing?.body ?? '',
      onSave: (title, body, _) => StudyNote(
        id: existing?.id ?? createId(),
        subjectId: subjectId,
        title: title,
        body: body,
      ),
    ),
  );
}

Future<StudyResource?> showResourceEditor(
  BuildContext context, {
  required String subjectId,
  StudyResource? existing,
}) {
  return showDialog<StudyResource>(
    context: context,
    builder: (context) => _TextRecordDialog<StudyResource>(
      title: existing == null ? 'Նոր աղբյուր' : 'Խմբագրել աղբյուրը',
      firstLabel: 'Վերնագիր',
      secondLabel: 'Հղում կամ կարճ բացատրություն',
      first: existing?.title ?? '',
      second: existing?.detail ?? '',
      onSave: (title, body, _) => StudyResource(
        id: existing?.id ?? createId(),
        subjectId: subjectId,
        title: title,
        detail: body,
      ),
    ),
  );
}

class _TextRecordDialog<T> extends StatefulWidget {
  const _TextRecordDialog({
    required this.title,
    required this.firstLabel,
    required this.secondLabel,
    required this.first,
    required this.second,
    required this.onSave,
    this.date,
  });

  final String title;
  final String firstLabel;
  final String secondLabel;
  final String first;
  final String second;
  final DateTime? date;
  final T Function(String title, String body, DateTime date) onSave;

  @override
  State<_TextRecordDialog<T>> createState() => _TextRecordDialogState<T>();
}

class _TextRecordDialogState<T> extends State<_TextRecordDialog<T>> {
  late final TextEditingController _first;
  late final TextEditingController _second;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.first);
    _second = TextEditingController(text: widget.second);
    _date = widget.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorDialog(
      title: widget.title,
      onSave: () {
        Navigator.pop(
          context,
          widget.onSave(_first.text.trim(), _second.text.trim(), dateOnly(_date)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _first,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.firstLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _second,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: widget.secondLabel),
          ),
          if (widget.date != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Օր'),
              subtitle: Text(formatDay(_date)),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null && context.mounted) setState(() => _date = picked);
              },
            ),
        ],
      ),
    );
  }
}
