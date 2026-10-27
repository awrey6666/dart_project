import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/academics.dart';
import '../models/study_data.dart';
import '../util/format.dart';
import '../widgets/editors.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  Future<void> _edit(BuildContext context, {GradeItem? existing}) async {
    final controller = StudyScope.of(context);
    if (controller.subjects.isEmpty) {
      showStudyMessage(context, 'Նախ ավելացրեք առարկա, հետո գրեք գնահատականը։');
      return;
    }
    final grade = await showGradeEditor(
      context,
      subjects: controller.subjects,
      existing: existing,
    );
    if (grade == null || !context.mounted) return;
    final message = await controller.saveGrade(grade);
    if (!context.mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _delete(BuildContext context, GradeItem grade) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Ջնջե՞լ այս գնահատականը',
      message: '«${grade.title}» այլևս չի մտնի միջինի մեջ։',
    );
    if (!confirmed || !context.mounted) return;
    final message = await StudyScope.of(context).deleteGrade(grade.id);
    if (!context.mounted) return;
    showStudyMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final overall = controller.overallAverage;
    final openSoon = controller.openHomework.where((item) {
      final delta = dateOnly(item.due).difference(dateOnly(DateTime.now())).inDays;
      return delta <= 7;
    }).length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Միջինը ըստ կրեդիտների', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      formatPercent(overall),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      overall == null
                          ? 'Գրեք գնահատական, որպեսզի միջինը հաշվվի։'
                          : 'Տառ ${Academics.letter(overall)}։ A՝ 90 և բարձր, B՝ 80, C՝ 70, D՝ 60։',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _MiniStat(
                          label: 'Արված աշխատանք',
                          value: '${controller.homework.where((item) => item.done).length}',
                        ),
                        _MiniStat(
                          label: 'Մոտակա 7 օրվա աշխատանք',
                          value: '$openSoon',
                        ),
                        _MiniStat(
                          label: 'Դասեր',
                          value: '${controller.lessons.length}',
                        ),
                        _MiniStat(
                          label: 'Առարկաներ',
                          value: '${controller.subjects.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Ըստ առարկայի'),
            if (controller.subjects.isEmpty)
              const EmptyHint(
                icon: Icons.insights_outlined,
                message: 'Առարկա և գնահատական ավելացնելուց հետո այստեղ կերևա միջինը։',
              )
            else
              for (final subject in controller.subjects) ...[
                _SubjectAverage(subject: subject, average: controller.averageFor(subject.id)),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            const SectionHeader(title: 'Հաշվել առանց պահելու'),
            const _QuickCalculator(),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Գնահատականներ'),
            if (controller.grades.isEmpty)
              const EmptyHint(
                icon: Icons.grading_outlined,
                message: 'Գրեք ստուգողական, լաբորատոր կամ շարադրություն, որպեսզի այն մտնի միջինի մեջ։',
              )
            else
              for (final grade in controller.grades) ...[
                _GradeTile(
                  grade: grade,
                  onEdit: () => _edit(context, existing: grade),
                  onDelete: () => _delete(context, grade),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Գնահատական'),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SubjectAverage extends StatelessWidget {
  const _SubjectAverage({required this.subject, required this.average});

  final Subject subject;
  final double? average;

  @override
  Widget build(BuildContext context) {
    final value = ((average ?? 0) / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: subject.color),
                const SizedBox(width: 8),
                Expanded(child: Text(subject.name)),
                Text(_averageLabel(average)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: average == null ? 0 : value),
          ],
        ),
      ),
    );
  }
}

String _averageLabel(double? average) {
  if (average == null) return 'Գնահատական չկա';
  return '${formatPercent(average)} ${Academics.letter(average)}';
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({
    required this.grade,
    required this.onEdit,
    required this.onDelete,
  });

  final GradeItem grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final subject = controller.subjectById(grade.subjectId);
    return StudyTile(
      color: subject?.color ?? Theme.of(context).colorScheme.primary,
      title: grade.title,
      subtitle: [
        subject?.name ?? 'Առարկա',
        '${grade.score}/${grade.maxScore} · կարևորություն ${grade.weight} · ${formatPercent(grade.percent)}',
        formatDay(grade.date),
      ].join('\n'),
      onTap: onEdit,
      trailing: ItemMenu(onEdit: onEdit, onDelete: onDelete),
    );
  }
}

class _QuickCalculator extends StatefulWidget {
  const _QuickCalculator();

  @override
  State<_QuickCalculator> createState() => _QuickCalculatorState();
}

class _QuickCalculatorState extends State<_QuickCalculator> {
  final _score = TextEditingController();
  final _max = TextEditingController(text: '100');
  final _weight = TextEditingController(text: '1');

  @override
  void dispose() {
    _score.dispose();
    _max.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = double.tryParse(_score.text);
    final max = double.tryParse(_max.text);
    final weight = double.tryParse(_weight.text);
    final percent = score != null && max != null && max > 0 && score >= 0 && score <= max
        ? score / max * 100
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Սա միայն նախադիտում է և չի պահվում։ Պահված գնահատականը փոխում է առարկայի միջինը ըստ կարևորության, իսկ առարկաները միանում են ըստ կրեդիտների։',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _field(_score, 'Ստացած միավոր'),
            const SizedBox(height: 8),
            _field(_max, 'Առավելագույն միավոր'),
            const SizedBox(height: 8),
            _field(_weight, 'Կարևորություն'),
            const SizedBox(height: 12),
            Text(
              percent == null
                  ? 'Գրեք ստացած միավորը, որպեսզի տեսնեք տոկոսը և տառը։'
                  : '${formatPercent(percent)} · ${Academics.letter(percent)}${weight != null && weight > 0 ? ' · կարևորություն $weight' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(labelText: label),
    );
  }
}
