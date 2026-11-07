import 'package:flutter/material.dart';

import '../widgets/study_widgets.dart';
import 'adaptive_engine.dart';
import 'learn_catalog.dart';
import 'learn_models.dart';
import 'learn_scope.dart';

/// Պրոֆիլ՝ մակարդակ, XP, առաջընթաց ըստ առարկաների, ձեռքբերումներ և պատմություն։
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    final profile = learn.profile;
    final user = learn.user;
    if (profile == null || user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final scheme = Theme.of(context).colorScheme;
    final totalAnswered = profile.stats.values.fold<int>(0, (s, e) => s + e.answered);
    final totalCorrect = profile.stats.values.fold<int>(0, (s, e) => s + e.correct);
    final accuracy = totalAnswered == 0 ? null : totalCorrect / totalAnswered * 100;
    final tried = [
      for (final s in learnSubjects)
        if (s.topics.any((t) => (profile.peekStats(t.id)?.answered ?? 0) > 0)) s,
    ];
    final recent = profile.history.reversed.take(8).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Պրոֆիլ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    child: Text(user.name.characters.first.toUpperCase()),
                  ),
                  title: Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text('Մակարդակ ${profile.level} · ${profile.rank.label}'),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tiles = [
                    StatTile(label: 'Փորձի միավոր', value: '${profile.xp} XP', icon: Icons.bolt_outlined),
                    StatTile(
                      label: 'Ճշտություն',
                      value: accuracy == null ? '—' : '${accuracy.toStringAsFixed(0)}%',
                      icon: Icons.track_changes_outlined,
                    ),
                    StatTile(
                      label: 'Օրեր անընդմեջ',
                      value: '${profile.streak}',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ];
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [for (final t in tiles) ...[t, const SizedBox(height: 8)]],
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
              const SectionHeader(title: 'Առաջընթաց ըստ առարկաների'),
              if (tried.isEmpty)
                const EmptyHint(
                  icon: Icons.insights_outlined,
                  message: 'Ավարտեք առաջին դասը, և այստեղ կերևա ձեր առաջընթացը։',
                )
              else
                for (final subject in tried) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          for (final topic in subject.topics)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(flex: 4, child: Text(topic.title)),
                                  Expanded(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 6,
                                        value: profile.peekStats(topic.id)?.mastery ?? 0,
                                        color: Color(subject.colorValue),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      '${((profile.peekStats(topic.id)?.mastery ?? 0) * 100).round()}% · ${(profile.peekStats(topic.id)?.stage ?? Stage.beginner).label}',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Ձեռքբերումներ (${profile.achievements.length}/${allAchievements.length})',
              ),
              for (final item in allAchievements)
                Builder(
                  builder: (context) {
                    final earned = profile.achievements.contains(item.id);
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          earned ? item.icon : Icons.lock_outline,
                          color: earned ? scheme.primary : scheme.outline,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(color: earned ? null : scheme.outline),
                        ),
                        subtitle: Text(item.description),
                        trailing: earned ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32)) : null,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Վերջին դասերը'),
              if (recent.isEmpty)
                const EmptyHint(icon: Icons.history, message: 'Դեռ դասեր չկան։')
              else
                for (final item in recent)
                  ListTile(
                    leading: const Icon(Icons.task_alt),
                    title: Text(subjectById(item.subjectId)?.title ?? item.subjectId),
                    subtitle: Text(
                      '${item.date.day.toString().padLeft(2, '0')}.${item.date.month.toString().padLeft(2, '0')}.${item.date.year}',
                    ),
                    trailing: Text('${item.correct}/${item.total} · +${item.xp} XP'),
                  ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await learn.logout();
                  navigator.pop();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Դուրս գալ հաշվից'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
