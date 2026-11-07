import 'dart:math';

import 'package:flutter/material.dart';

import 'learn_catalog.dart';
import 'learn_models.dart';

// ---------------------------------------------------------------------------
// Բացվող մակարդակներ և թեմաներ (կախված է գիտելիքից և արդյունքներից)
// ---------------------------------------------------------------------------

class Unlocks {
  const Unlocks._();

  /// Մակարդակը բացվում է ըստ յուրացման աստիճանի և պատասխանների քանակի։
  static bool stageUnlocked(LearnProfile profile, String topicId, Stage stage) {
    final stats = profile.peekStats(topicId);
    switch (stage) {
      case Stage.beginner:
        return true;
      case Stage.intermediate:
        return stats != null && stats.mastery >= 0.4 && stats.answered >= 5;
      case Stage.advanced:
        return stats != null && stats.mastery >= 0.7 && stats.answered >= 12;
    }
  }

  /// Հաջորդ թեման բացվում է, երբ նախորդը բավարար յուրացված է։
  static bool topicUnlocked(LearnProfile profile, LearnSubject subject, int index) {
    if (index <= 0) return true;
    final previous = profile.peekStats(subject.topics[index - 1].id);
    return previous != null && previous.mastery >= 0.5 && previous.answered >= 5;
  }

  /// Բոլոր բացված (թեմա, մակարդակ) զույգերի ստեղներ՝ նոր բացվածները գտնելու համար։
  static Set<String> snapshot(LearnProfile profile) {
    final out = <String>{};
    for (final subject in learnSubjects) {
      for (var i = 0; i < subject.topics.length; i++) {
        final topic = subject.topics[i];
        if (topicUnlocked(profile, subject, i)) out.add('topic:${topic.id}');
        for (final stage in Stage.values) {
          if (stageUnlocked(profile, topic.id, stage)) {
            out.add('stage:${topic.id}:${stage.name}');
          }
        }
      }
    }
    return out;
  }

  /// Սկզբնական բարդություն՝ ըստ թեմայի յուրացման։
  static int startDifficulty(double mastery, Stage stage) {
    final byMastery = (1 + mastery * 4).round();
    return byMastery.clamp(stage.minDifficulty, stage.maxDifficulty).toInt();
  }

  /// Ամենաթույլ թեմաները «խելացի կրկնության» համար։
  static List<Topic> weakTopics(LearnProfile profile, LearnSubject subject, {int take = 2}) {
    final open = <Topic>[];
    for (var i = 0; i < subject.topics.length; i++) {
      if (topicUnlocked(profile, subject, i)) open.add(subject.topics[i]);
    }
    final practiced = open.where((t) => (profile.peekStats(t.id)?.answered ?? 0) > 0).toList();
    final pool = practiced.isEmpty ? [open.first] : practiced;
    pool.sort((a, b) {
      final ma = profile.peekStats(a.id)?.mastery ?? 0;
      final mb = profile.peekStats(b.id)?.mastery ?? 0;
      return ma.compareTo(mb);
    });
    return pool.take(take).toList();
  }
}

// ---------------------------------------------------------------------------
// Դասի ընթացք՝ ադապտիվ բարդությամբ
// ---------------------------------------------------------------------------

class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.topicId,
    required this.difficulty,
    required this.correct,
    required this.ms,
    required this.isRetry,
  });

  final String questionId;
  final String topicId;
  final int difficulty;
  final bool correct;
  final int ms;
  final bool isRetry;
}

class AnswerOutcome {
  const AnswerOutcome({
    required this.question,
    required this.correct,
    required this.xp,
    required this.difficultyChange,
    required this.newDifficulty,
    required this.needsHelp,
    this.helpText,
  });

  final Question question;
  final bool correct;
  final int xp;

  /// +1՝ հաջորդ հարցերը ավելի բարդ կլինեն, -1՝ ավելի հեշտ, 0՝ նույն։
  final int difficultyChange;
  final int newDifficulty;
  final bool needsHelp;
  final String? helpText;
}

class SessionSummary {
  const SessionSummary({
    required this.subjectId,
    required this.topicIds,
    required this.answers,
    required this.xp,
    required this.endDifficulty,
  });

  final String subjectId;
  final List<String> topicIds;
  final List<AnswerRecord> answers;
  final int xp;
  final int endDifficulty;

  int get total => answers.length;
  int get correct => answers.where((a) => a.correct).length;
  bool get perfect => total >= 5 && correct == total;
  bool get retryRecovered => answers.any((a) => a.isRetry && a.correct);
  double get accuracy => total == 0 ? 0 : correct / total;
}

class _Retry {
  _Retry(this.question, this.due);
  final Question question;
  final int due;
}

class LessonSession {
  LessonSession({
    required this.subject,
    required this.topics,
    required this.stage,
    required this.pool,
    required this.profile,
    required int startDifficulty,
    this.length = 10,
    Random? random,
  }) : difficulty = startDifficulty.clamp(1, 5).toInt(),
       _random = random ?? Random();

  final LearnSubject subject;
  final List<Topic> topics;
  final Stage stage;
  final List<Question> pool;
  final LearnProfile profile;
  final int length;
  final Random _random;

  int difficulty;
  Question? current;
  bool currentIsRetry = false;

  final answers = <AnswerRecord>[];
  final _used = <String>{};
  final _retry = <_Retry>[];
  final _window = <double>[];
  var _wrongStreak = 0;
  String? _focusTopic;
  QuestionType? _lastType;
  var _xp = 0;

  int get answered => answers.length;
  bool get finished => answered >= length;

  /// Ընտրում է հաջորդ հարցը՝ ըստ ընթացիկ բարդության, նախորդ սխալների և տեսակների բազմազանության։
  Question? next() {
    if (finished) return current = null;

    for (var i = 0; i < _retry.length; i++) {
      if (_retry[i].due <= answered) {
        final item = _retry.removeAt(i);
        currentIsRetry = true;
        _lastType = item.question.type;
        return current = item.question;
      }
    }
    currentIsRetry = false;

    final candidates = pool.where((q) => !_used.contains(q.id)).toList();
    if (candidates.isEmpty) {
      if (_retry.isNotEmpty) {
        final item = _retry.removeAt(0);
        currentIsRetry = true;
        return current = item.question;
      }
      return current = null;
    }

    var best = 99;
    for (final q in candidates) {
      best = min(best, (q.difficulty - difficulty).abs());
    }
    var group = candidates.where((q) => (q.difficulty - difficulty).abs() == best).toList();

    if (_focusTopic != null) {
      final focused = group.where((q) => q.topicId == _focusTopic).toList();
      if (focused.isNotEmpty) group = focused;
    }
    final previouslyWrong = group.where((q) => (profile.mistakes[q.id] ?? 0) > 0).toList();
    if (previouslyWrong.isNotEmpty && _random.nextDouble() < 0.5) {
      group = previouslyWrong;
    }
    final varied = group.where((q) => q.type != _lastType).toList();
    if (varied.isNotEmpty) group = varied;

    final picked = group[_random.nextInt(group.length)];
    _used.add(picked.id);
    _lastType = picked.type;
    return current = picked;
  }

  double _valueFor(Question q, bool correct, int ms) {
    if (!correct) return 0;
    final slowTypes = {
      QuestionType.numeric,
      QuestionType.code,
      QuestionType.open,
      QuestionType.ordering,
      QuestionType.matching,
    };
    final scale = slowTypes.contains(q.type) ? 3 : 1;
    if (ms < 8000 * scale) return 1.0;
    if (ms <= 45000 * scale) return 0.8;
    return 0.6;
  }

  AnswerOutcome submit(Object? answer, int ms) {
    final q = current!;
    final correct = q.check(answer);
    final retry = currentIsRetry;

    answers.add(AnswerRecord(
      questionId: q.id,
      topicId: q.topicId,
      difficulty: q.difficulty,
      correct: correct,
      ms: ms,
      isRetry: retry,
    ));

    var gained = 0;
    if (correct) {
      gained = retry ? 5 : 8 + 4 * q.difficulty;
      _xp += gained;
    }

    _window.add(_valueFor(q, correct, ms));
    if (_window.length > 3) _window.removeAt(0);
    _wrongStreak = correct ? 0 : _wrongStreak + 1;

    var change = 0;
    var needsHelp = false;
    String? helpText;
    final average = _window.isEmpty ? 0.0 : _window.reduce((a, b) => a + b) / _window.length;

    if (!correct) {
      _focusTopic = q.topicId;
      if (!retry) _retry.add(_Retry(q, answered + 3));
    }

    if (_window.length >= 3 && average >= 0.85 && difficulty < stage.maxDifficulty) {
      difficulty++;
      change = 1;
      _window.clear();
      _focusTopic = null;
    } else if (_wrongStreak >= 2 || (_window.length >= 3 && average <= 0.34)) {
      needsHelp = true;
      helpText = topicById(q.topicId)?.tip;
      if (difficulty > 1) {
        difficulty--;
        change = -1;
      }
      _window.clear();
      _wrongStreak = 0;
    }

    return AnswerOutcome(
      question: q,
      correct: correct,
      xp: gained,
      difficultyChange: change,
      newDifficulty: difficulty,
      needsHelp: needsHelp,
      helpText: helpText,
    );
  }

  SessionSummary summary() {
    var bonus = 0;
    final total = answers.length;
    final correct = answers.where((a) => a.correct).length;
    if (total > 0) bonus += 20;
    if (total >= 5 && correct == total) bonus += 30;
    return SessionSummary(
      subjectId: subject.id,
      topicIds: topics.map((t) => t.id).toList(),
      answers: List.unmodifiable(answers),
      xp: _xp + bonus,
      endDifficulty: difficulty,
    );
  }
}

// ---------------------------------------------------------------------------
// Ձեռքբերումներ
// ---------------------------------------------------------------------------

class Achievement {
  const Achievement(this.id, this.title, this.description, this.icon);

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

const allAchievements = <Achievement>[
  Achievement('first', 'Առաջին քայլ', 'Ավարտեք առաջին դասը', Icons.flag_outlined),
  Achievement('perfect', 'Անթերի', 'Պատասխանեք բոլոր հարցերին ճիշտ (առնվազն 5)', Icons.verified_outlined),
  Achievement('streak3', '3 օր անընդմեջ', 'Սովորեք 3 օր շարունակ', Icons.local_fire_department_outlined),
  Achievement('streak7', 'Շաբաթվա հերոս', 'Սովորեք 7 օր շարունակ', Icons.whatshot_outlined),
  Achievement('xp100', '100 XP', 'Հավաքեք 100 փորձի միավոր', Icons.bolt_outlined),
  Achievement('xp500', '500 XP', 'Հավաքեք 500 փորձի միավոր', Icons.electric_bolt_outlined),
  Achievement('level5', '5-րդ մակարդակ', 'Հասեք 5-րդ մակարդակի', Icons.trending_up),
  Achievement('explorer', 'Հետազոտող', 'Փորձեք առնվազն 3 տարբեր առարկա', Icons.explore_outlined),
  Achievement('master', 'Վարպետ', 'Հասեք 85% յուրացման որևէ թեմայում (առնվազն 10 պատասխան)', Icons.workspace_premium_outlined),
  Achievement('hard5', 'Դժվարների նվաճող', 'Ճիշտ պատասխանեք 5 ամենաբարդ հարցերի', Icons.terrain_outlined),
  Achievement('comeback', 'Չհանձնվող', 'Ճիշտ պատասխանեք նախկինում սխալված հարցին', Icons.replay_circle_filled_outlined),
];

Achievement? achievementById(String id) {
  for (final item in allAchievements) {
    if (item.id == id) return item;
  }
  return null;
}

/// Վերադարձնում է նոր ստացված ձեռքբերումների id-ները (չի փոփոխում profile-ը)։
List<String> evaluateAchievements(LearnProfile profile, {SessionSummary? session}) {
  final earned = <String>[];
  void check(String id, bool condition) {
    if (condition && !profile.achievements.contains(id)) earned.add(id);
  }

  final subjectsTried = <String>{};
  for (final topicId in profile.stats.keys) {
    final topic = topicById(topicId);
    if (topic != null && (profile.stats[topicId]?.answered ?? 0) > 0) {
      subjectsTried.add(topic.subjectId);
    }
  }
  final mastered = profile.stats.values.any((s) => s.mastery >= 0.85 && s.answered >= 10);

  check('first', profile.history.isNotEmpty);
  check('perfect', session?.perfect ?? false);
  check('streak3', profile.streak >= 3);
  check('streak7', profile.streak >= 7);
  check('xp100', profile.xp >= 100);
  check('xp500', profile.xp >= 500);
  check('level5', profile.level >= 5);
  check('explorer', subjectsTried.length >= 3);
  check('master', mastered);
  check('hard5', profile.hardCorrect >= 5);
  check('comeback', session?.retryRecovered ?? false);
  return earned;
}
