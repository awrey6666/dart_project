import 'package:flutter/material.dart';

import 'adaptive_engine.dart';
import 'learn_controller.dart';
import 'learn_models.dart';
import 'learn_scope.dart';
import 'question_view.dart';

/// Դասի էջ՝ հարցերի շարք, ադապտիվ բարդություն և արդյունքների ամփոփում։
class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.start, required this.title});

  final Future<LessonSession> Function() start;
  final String title;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  LessonSession? _session;
  String? _error;
  Question? _question;
  AnswerOutcome? _outcome;
  SessionReward? _reward;
  SessionSummary? _summary;
  Object? _answer;
  var _counter = 0;
  var _done = false;
  var _shownAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  void _restart() {
    setState(() {
      _session = null;
      _error = null;
      _question = null;
      _outcome = null;
      _reward = null;
      _summary = null;
      _answer = null;
      _done = false;
    });
    _boot();
  }

  Future<void> _boot() async {
    try {
      final session = await widget.start();
      if (!mounted) return;
      _session = session;
      _advance();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Չհաջողվեց պատրաստել դասը։');
    }
  }

  void _advance() {
    final session = _session!;
    final next = session.next();
    if (next == null) {
      _complete();
      return;
    }
    setState(() {
      _question = next;
      _outcome = null;
      _answer = null;
      _counter++;
      _shownAt = DateTime.now();
    });
  }

  Future<void> _complete() async {
    final session = _session!;
    final learn = LearnScope.of(context);
    final summary = session.summary();
    final reward = await learn.finish(session);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _reward = reward;
      _done = true;
      _question = null;
    });
  }

  void _check() {
    final session = _session;
    if (session == null || _outcome != null || _answer == null) return;
    final ms = DateTime.now().difference(_shownAt).inMilliseconds;
    setState(() => _outcome = session.submit(_answer, ms));
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Դուրս գա՞լ դասից'),
        content: const Text('Մինչ այժմ տված պատասխանները կպահպանվեն։'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Շարունակել'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Դուրս գալ'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    final navigator = Navigator.of(context);
    await LearnScope.of(context).finish(_session!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final canLeaveFreely = _done || session == null || session.answered == 0;
    return PopScope(
      canPop: canLeaveFreely,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _restart, child: const Text('Կրկին փորձել')),
          ],
        ),
      );
    }
    if (_session == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Պատրաստվում են հարցերը…'),
          ],
        ),
      );
    }
    if (_done) return _result(context);
    final q = _question;
    if (q == null) return const SizedBox.shrink();
    return _questionBody(context, q);
  }

  // ------------------------- Հարց -------------------------

  Widget _questionBody(BuildContext context, Question q) {
    final session = _session!;
    final scheme = Theme.of(context).colorScheme;
    final outcome = _outcome;
    final isLast = session.answered >= session.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: session.answered / session.length,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${session.answered}/${session.length}'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.category_outlined, size: 16),
              label: Text(q.type.label),
            ),
            _DifficultyDots(level: q.difficulty),
            if (session.currentIsRetry)
              const Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(Icons.replay, size: 16),
                label: Text('Կրկնություն'),
              ),
            if (q.generated)
              const Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(Icons.auto_awesome, size: 16),
                label: Text('Նոր հարց'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: QuestionView(
              key: ValueKey('${q.id}#$_counter'),
              question: q,
              revealed: outcome != null,
              onChanged: (value) => setState(() => _answer = value),
              onSubmit: _check,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (outcome == null)
          FilledButton(
            onPressed: _answer == null ? null : _check,
            child: const Text('Ստուգել'),
          )
        else ...[
          _feedback(context, outcome),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _advance,
            icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
            label: Text(isLast ? 'Ավարտել' : 'Հաջորդը'),
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Ընթացիկ բարդություն՝ ${session.difficulty}/5',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _feedback(BuildContext context, AnswerOutcome outcome) {
    final scheme = Theme.of(context).colorScheme;
    final q = outcome.question;
    final color = outcome.correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final change = switch (outcome.difficultyChange) {
      1 => 'Հիանալի է․ հաջորդ հարցերը կլինեն ավելի բարդ։',
      -1 => 'Կառաջարկենք ավելի պարզ հարցեր՝ այս թեման ամրապնդելու համար։',
      _ => null,
    };
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(outcome.correct ? Icons.check_circle : Icons.cancel, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    outcome.correct ? 'Ճիշտ է։' : 'Սխալ է։',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                if (outcome.xp > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.bolt, size: 16),
                    label: Text('+${outcome.xp} XP'),
                  ),
              ],
            ),
            if (!outcome.correct && q.correctAnswerText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ճիշտ պատասխանը՝', style: TextStyle(color: scheme.onSurfaceVariant)),
              SelectableText(q.correctAnswerText,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (q.type == QuestionType.open && outcome.correct) ...[
              const SizedBox(height: 8),
              Text(q.correctAnswerText, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
            if (q.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(q.explanation),
            ],
            if (!outcome.correct) ...[
              const SizedBox(height: 8),
              Text(
                'Այս հարցին կվերադառնանք մի քանի հարցից հետո։',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            if (outcome.needsHelp && outcome.helpText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Պարզ բացատրություն',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(outcome.helpText!, style: TextStyle(color: scheme.onTertiaryContainer)),
                  ],
                ),
              ),
            ],
            if (change != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    outcome.difficultyChange > 0 ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(change, style: TextStyle(color: scheme.primary))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------- Արդյունք -------------------------

  Widget _result(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _summary!;
    final reward = _reward!;
    final percent = (summary.accuracy * 100).round();
    final message = percent >= 90
        ? 'Գերազանց արդյունք։'
        : percent >= 60
        ? 'Լավ աշխատանք։ Շարունակեք։'
        : 'Մի հուսահատվեք. կրկնությունը կօգնի ամրապնդել թեման։';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  percent >= 60 ? Icons.emoji_events : Icons.fitness_center,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.correct} / ${summary.total}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final answer in summary.answers)
                      Icon(
                        answer.correct ? Icons.check_circle : Icons.cancel,
                        size: 20,
                        color: answer.correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text('+${reward.xpGained} XP'),
                ),
              ],
            ),
          ),
        ),
        if (reward.leveledUp) ...[
          const SizedBox(height: 12),
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.arrow_circle_up, color: scheme.onPrimaryContainer),
              title: Text(
                'Նոր մակարդակ՝ ${reward.levelAfter}',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        if (reward.achievements.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final item in reward.achievements)
            Card(
              child: ListTile(
                leading: Icon(item.icon, color: scheme.primary),
                title: Text('Ձեռքբերում՝ ${item.title}'),
                subtitle: Text(item.description),
              ),
            ),
        ],
        if (reward.unlocked.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final text in reward.unlocked)
            Card(
              child: ListTile(
                leading: Icon(Icons.lock_open, color: scheme.primary),
                title: Text(text),
                subtitle: const Text('Բացվեց նոր փուլ'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay),
                label: const Text('Նորից'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ավարտել'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Բարդություն ', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              i <= level ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: scheme.primary,
            ),
          ),
      ],
    );
  }
}
