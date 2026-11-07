import 'package:flutter/material.dart';

import '../widgets/study_widgets.dart';
import 'adaptive_engine.dart';
import 'learn_catalog.dart';
import 'learn_controller.dart';
import 'learn_models.dart';
import 'learn_scope.dart';
import 'lesson_page.dart';

/// «Սովորել» ներդիր՝ առարկաներ, թեմաներ, մակարդակներ և խելացի կրկնություն։
class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile;
    if (profile == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final subjects = learn.selectedSubjects;
    final resume = learn.continueTopic;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _LevelCard(profile: profile),
            if (resume != null) ...[
              const SizedBox(height: 12),
              _ResumeCard(topic: resume),
            ],
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Իմ առարկաները',
              action: TextButton.icon(
                onPressed: () => _pickSubjects(context),
                icon: const Icon(Icons.tune),
                label: const Text('Ընտրել'),
              ),
            ),
            if (subjects.isEmpty)
              Column(
                children: [
                  const EmptyHint(
                    icon: Icons.checklist_outlined,
                    message: 'Ընտրեք ձեզ հետաքրքրող առարկաները՝ ուսուցումը սկսելու համար։',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _pickSubjects(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ընտրել առարկաներ'),
                  ),
                ],
              )
            else
              for (final subject in subjects) ...[
                _SubjectCard(subject: subject),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
            Text(
              'Հարցերը հարմարվում են ձեր պատասխաններին՝ ճիշտ պատասխանների դեպքում դառնում են ավելի բարդ, '
              'իսկ դժվարության դեպքում՝ ավելի պարզ՝ լրացուցիչ բացատրություններով։',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

void _pickSubjects(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _SubjectPicker());
}

void openLesson(
  BuildContext context, {
  required String title,
  required Future<LessonSession> Function() start,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonPage(start: start, title: title)),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.profile});

  final LearnProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = profile.xpForNextLevel == 0
        ? 0.0
        : (profile.xpIntoLevel / profile.xpForNextLevel).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${profile.level}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Մակարդակ ${profile.level} · ${profile.rank.label}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${profile.xp} XP',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 18),
                  label: Text('${profile.streak} օր'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(minHeight: 10, value: progress),
            ),
            const SizedBox(height: 4),
            Text(
              'Հաջորդ մակարդակին՝ ${profile.xpForNextLevel - profile.xpIntoLevel} XP',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile!;
    final subject = subjectById(topic.subjectId);
    var stage = profile.peekStats(topic.id)?.stage ?? Stage.beginner;
    while (stage != Stage.beginner && !Unlocks.stageUnlocked(profile, topic.id, stage)) {
      stage = Stage.values[stage.index - 1];
    }
    final chosenStage = stage;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline, size: 32),
        title: const Text('Շարունակել ուսուցումը'),
        subtitle: Text('${subject?.title ?? ''} · ${topic.title} · ${chosenStage.label}'),
        trailing: FilledButton(
          onPressed: () => openLesson(
            context,
            title: topic.title,
            start: () => learn.startTopic(topic, chosenStage),
          ),
          child: const Text('Սկսել'),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final LearnSubject subject;

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile!;
    final color = Color(subject.colorValue);
    final mastery = learn.subjectMastery(subject);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(Icons.auto_stories, color: color),
        ),
        title: Text(subject.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(minHeight: 6, value: mastery, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(mastery * 100).round()}%'),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => openLesson(
                context,
                title: '${subject.title} · խելացի կրկնություն',
                start: () => learn.startSmart(subject),
              ),
              icon: const Icon(Icons.psychology_alt_outlined),
              label: const Text('Խելացի կրկնություն'),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < subject.topics.length; i++)
            _TopicRow(
              subject: subject,
              index: i,
              unlocked: Unlocks.topicUnlocked(profile, subject, i),
            ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.subject, required this.index, required this.unlocked});

  final LearnSubject subject;
  final int index;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile!;
    final scheme = Theme.of(context).colorScheme;
    final topic = subject.topics[index];
    final stats = profile.peekStats(topic.id);
    final mastery = stats?.mastery ?? 0;

    if (!unlocked) {
      final previous = subject.topics[index - 1];
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline),
        title: Text(topic.title),
        subtitle: Text('Բացվում է, երբ «${previous.title}» թեման յուրացնեք 50%-ով (առնվազն 5 պատասխան)։'),
        enabled: false,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(
                stats == null || stats.answered == 0
                    ? 'Նոր'
                    : '${(mastery * 100).round()}% · ${stats.stage.label}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(minHeight: 5, value: mastery),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final stage in Stage.values)
                _stageChip(context, learn, profile, topic, stage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageChip(
    BuildContext context,
    LearnController learn,
    LearnProfile profile,
    Topic topic,
    Stage stage,
  ) {
    final open = Unlocks.stageUnlocked(profile, topic.id, stage);
    final hint = switch (stage) {
      Stage.beginner => '',
      Stage.intermediate => 'Բացվում է 40% յուրացումից և 5 պատասխանից հետո',
      Stage.advanced => 'Բացվում է 70% յուրացումից և 12 պատասխանից հետո',
    };
    return Tooltip(
      message: open ? stage.label : hint,
      child: ActionChip(
        avatar: Icon(open ? Icons.play_arrow : Icons.lock_outline, size: 18),
        label: Text(stage.label),
        onPressed: open
            ? () => openLesson(
                context,
                title: '${topic.title} · ${stage.label}',
                start: () => learn.startTopic(topic, stage),
              )
            : null,
      ),
    );
  }
}

class _SubjectPicker extends StatelessWidget {
  const _SubjectPicker();

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile;
    if (profile == null) return const SizedBox.shrink();
    return AlertDialog(
      title: const Text('Ընտրեք առարկաները'),
      content: SizedBox(
        width: 440,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final group in learnGroups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                child: Text(
                  group,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              for (final subject in learnSubjects.where((s) => s.group == group))
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: profile.subjects.contains(subject.id),
                  title: Text(subject.title),
                  onChanged: (_) => learn.toggleSubject(subject.id),
                ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Պատրաստ է'),
        ),
      ],
    );
  }
}
