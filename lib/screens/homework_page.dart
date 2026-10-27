import 'package:flutter/material.dart';

import '../models/study_data.dart';
import '../util/format.dart';
import '../widgets/editors.dart';
import '../widgets/study_widgets.dart';
import 'study_scope.dart';

enum HomeworkFilter { open, done, all }

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  var _filter = HomeworkFilter.open;

  Future<void> _edit({HomeworkItem? existing}) async {
    final controller = StudyScope.of(context);
    if (controller.subjects.isEmpty) {
      showStudyMessage(context, 'Նախ ավելացրեք առարկա, հետո գրեք աշխատանքը։');
      return;
    }
    final item = await showHomeworkEditor(
      context,
      subjects: controller.subjects,
      existing: existing,
    );
    if (item == null || !mounted) return;
    final message = await controller.saveHomework(item);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  Future<void> _delete(HomeworkItem item) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Ջնջե՞լ այս աշխատանքը',
      message: '«${item.title}» կհանվի ցուցակից։',
    );
    if (!confirmed || !mounted) return;
    final controller = StudyScope.of(context);
    final message = await controller.deleteHomework(item.id);
    if (!mounted) return;
    showStudyMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    final items = controller.homework.where((item) {
      return switch (_filter) {
        HomeworkFilter.open => !item.done,
        HomeworkFilter.done => item.done,
        HomeworkFilter.all => true,
      };
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<HomeworkFilter>(
                  selected: {_filter},
                  onSelectionChanged: (value) => setState(() => _filter = value.first),
                  segments: const [
                    ButtonSegment(value: HomeworkFilter.open, label: Text('Չարված')),
                    ButtonSegment(value: HomeworkFilter.done, label: Text('Արված')),
                    ButtonSegment(value: HomeworkFilter.all, label: Text('Բոլորը')),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Սեղմեք վիճակի կոճակը՝ անելիք, ընթացքում, արված։'),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyHint(
                      icon: Icons.assignment_outlined,
                      message: switch (_filter) {
                        HomeworkFilter.open => 'Չարված աշխատանք չկա։',
                        HomeworkFilter.done => 'Արված աշխատանք չկա։',
                        HomeworkFilter.all => 'Աշխատանք դեռ չկա։ Ավելացրեք ներքևի կոճակով։',
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final subject = controller.subjectById(item.subjectId);
                        final overdue =
                            !item.done && dateOnly(item.due).isBefore(dateOnly(DateTime.now()));
                        final notes = item.notes.isEmpty ? null : item.notes;
                        return StudyTile(
                          color: subject?.color ?? Theme.of(context).colorScheme.primary,
                          title: item.title,
                          subtitle: [
                            subject?.name ?? 'Առարկա',
                            '${priorityLabel(item.priority)} · ${statusLabel(item.status)}',
                            dueLabel(item.due),
                            ?notes,
                          ].join('\n'),
                          onTap: () => _edit(existing: item),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (overdue)
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              TextButton(
                                onPressed: () async {
                                  final next = switch (item.status) {
                                    TaskStatus.todo => TaskStatus.doing,
                                    TaskStatus.doing => TaskStatus.done,
                                    TaskStatus.done => TaskStatus.todo,
                                  };
                                  final message = await controller.setHomeworkStatus(item.id, next);
                                  if (!context.mounted) return;
                                  showStudyMessage(context, message);
                                },
                                child: Text(statusLabel(item.status)),
                              ),
                              ItemMenu(
                                onEdit: () => _edit(existing: item),
                                onDelete: () => _delete(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Աշխատանք'),
          ),
        ),
      ],
    );
  }
}
