import 'package:flutter/material.dart';

import '../widgets/editors.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';
import 'subject_detail_page.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  Future<void> _edit(BuildContext context, {String? id}) async {
    final controller = StudyScope.of(context);
    final existing = id == null ? null : controller.subjectById(id);
    final subject = await showSubjectEditor(context, existing: existing);
    if (subject == null || !context.mounted) return;
    final message = await controller.saveSubject(subject);
    if (!context.mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _delete(BuildContext context, String id) async {
    final controller = StudyScope.of(context);
    final subject = controller.subjectById(id);
    final confirmed = await confirmDelete(
      context,
      title: 'Ջնջե՞լ ${subject?.name ?? 'առարկան'}',
      message: 'Այս առարկայի դասերը, աշխատանքները, քննությունները և գնահատականները նույնպես կջնջվեն։',
    );
    if (!confirmed || !context.mounted) return;
    final message = await controller.deleteSubject(id);
    if (!context.mounted) return;
    showStudyMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final subjects = controller.subjects;
    return Stack(
      children: [
        subjects.isEmpty
            ? const EmptyHint(
                icon: Icons.menu_book_outlined,
                message: 'Ավելացրեք այս կիսամյակի առարկաները։',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: subjects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final average = controller.averageFor(subject.id);
                  final details = [
                    if (subject.teacher.isNotEmpty) subject.teacher,
                    if (subject.room.isNotEmpty) subject.room,
                    '${subject.credits.toStringAsFixed(subject.credits == subject.credits.roundToDouble() ? 0 : 1)} կրեդիտ',
                    if (average != null) 'միջին ${average.toStringAsFixed(1)}%',
                  ].join(' · ');
                  return StudyTile(
                    color: subject.color,
                    title: subject.name,
                    subtitle: details,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => SubjectDetailPage(subjectId: subject.id),
                        ),
                      );
                    },
                    trailing: ItemMenu(
                      onEdit: () => _edit(context, id: subject.id),
                      onDelete: () => _delete(context, subject.id),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Առարկա'),
          ),
        ),
      ],
    );
  }
}
