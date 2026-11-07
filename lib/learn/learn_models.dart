import 'dart:math' as math;

/// Բարդության մակարդակ (սկսնակ / միջին / առաջադեմ).
enum Stage { beginner, intermediate, advanced }

extension StageInfo on Stage {
  String get label => switch (this) {
    Stage.beginner => 'Սկսնակ',
    Stage.intermediate => 'Միջին',
    Stage.advanced => 'Առաջադեմ',
  };

  int get minDifficulty => switch (this) {
    Stage.beginner => 1,
    Stage.intermediate => 2,
    Stage.advanced => 4,
  };

  int get maxDifficulty => switch (this) {
    Stage.beginner => 2,
    Stage.intermediate => 4,
    Stage.advanced => 5,
  };

  int get startDifficulty => switch (this) {
    Stage.beginner => 1,
    Stage.intermediate => 3,
    Stage.advanced => 4,
  };
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  matching,
  ordering,
  numeric,
  code,
  open,
}

extension QuestionTypeInfo on QuestionType {
  String get label => switch (this) {
    QuestionType.multipleChoice => 'Ընտրություն',
    QuestionType.trueFalse => 'Ճիշտ / սխալ',
    QuestionType.fillBlank => 'Լրացում',
    QuestionType.matching => 'Համապատասխանություն',
    QuestionType.ordering => 'Հերթականություն',
    QuestionType.numeric => 'Հաշվարկ',
    QuestionType.code => 'Կոդային առաջադրանք',
    QuestionType.open => 'Բացատրություն',
  };
}

String normalizeAnswer(String value) {
  var text = value.trim().toLowerCase();
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  text = text.replaceAll(RegExp(r'[;.]+$'), '');
  if (text.length >= 2 &&
      ((text.startsWith('"') && text.endsWith('"')) ||
          (text.startsWith("'") && text.endsWith("'")))) {
    text = text.substring(1, text.length - 1);
  }
  return text.trim();
}

/// Մեկ հարց։ Պատասխանի ձևը կախված է [type]-ից՝
///  * multipleChoice / trueFalse -> `int` (ընտրված տարբերակի ինդեքսը)
///  * fillBlank / numeric / code -> `String`
///  * ordering -> `List<int>` ([options]-ի ինդեքսները օգտատիրոջ դասավորությամբ)
///  * matching -> `List<int>` (յուրաքանչյուր ձախ տարրի համար ընտրված աջ տարրի ինդեքսը)
///  * open -> `String` (ստուգվում է հիմնաբառերով)
class Question {
  const Question({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.explanation,
    this.options = const [],
    this.rights = const [],
    this.answerIndex = 0,
    this.accepted = const [],
    this.numericAnswer,
    this.keywords = const [],
    this.generated = false,
  });

  final String id;
  final String subjectId;
  final String topicId;
  final QuestionType type;
  final int difficulty; // 1..5
  final String prompt;
  final String explanation;

  /// multipleChoice: տարբերակներ; ordering: ճիշտ հերթականությամբ տարրեր;
  /// matching: ձախ տարրեր։
  final List<String> options;

  /// matching: աջ տարրեր (i-րդը համապատասխանում է options[i]-ին)։
  final List<String> rights;
  final int answerIndex;
  final List<String> accepted;
  final double? numericAnswer;
  final List<String> keywords;
  final bool generated;

  bool check(Object? answer) {
    switch (type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return answer is int && answer == answerIndex;
      case QuestionType.fillBlank:
      case QuestionType.code:
        if (answer is! String) return false;
        final given = normalizeAnswer(answer);
        if (given.isEmpty) return false;
        return accepted.any((item) => normalizeAnswer(item) == given);
      case QuestionType.numeric:
        if (answer is! String || numericAnswer == null) return false;
        final parsed = double.tryParse(answer.trim().replaceAll(',', '.'));
        if (parsed == null) return false;
        final tolerance = math.max(0.01, numericAnswer!.abs() * 0.001);
        return (parsed - numericAnswer!).abs() <= tolerance;
      case QuestionType.ordering:
        if (answer is! List<int> || answer.length != options.length) return false;
        for (var i = 0; i < answer.length; i++) {
          if (answer[i] != i) return false;
        }
        return true;
      case QuestionType.matching:
        if (answer is! List<int> || answer.length != options.length) return false;
        for (var i = 0; i < answer.length; i++) {
          if (answer[i] != i) return false;
        }
        return true;
      case QuestionType.open:
        if (answer is! String) return false;
        final text = normalizeAnswer(answer);
        if (text.length < 12) return false;
        if (keywords.isEmpty) return true;
        final hits = keywords
            .where((word) => text.contains(normalizeAnswer(word)))
            .length;
        return hits >= (keywords.length / 2).ceil();
    }
  }

  /// Ճիշտ պատասխանի տեքստային նկարագրություն (ցուցադրվում է սխալից հետո)։
  String get correctAnswerText {
    switch (type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return options[answerIndex];
      case QuestionType.fillBlank:
      case QuestionType.code:
        return accepted.isEmpty ? '' : accepted.first;
      case QuestionType.numeric:
        final value = numericAnswer ?? 0;
        return value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();
      case QuestionType.ordering:
        return options.join(' → ');
      case QuestionType.matching:
        return [
          for (var i = 0; i < options.length; i++) '${options[i]} — ${rights[i]}',
        ].join('\n');
      case QuestionType.open:
        return keywords.isEmpty ? '' : 'Հիմնաբառեր՝ ${keywords.join(', ')}';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'topicId': topicId,
    'type': type.name,
    'difficulty': difficulty,
    'prompt': prompt,
    'explanation': explanation,
    'options': options,
    'rights': rights,
    'answerIndex': answerIndex,
    'accepted': accepted,
    'numericAnswer': numericAnswer,
    'keywords': keywords,
  };

  factory Question.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String subjectId,
    required String topicId,
    bool generated = true,
  }) {
    final type = QuestionType.values.firstWhere(
      (item) => item.name == json['type'],
      orElse: () => QuestionType.multipleChoice,
    );
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const []).map((e) => '$e').toList();
    final options = strings('options');
    final rights = strings('rights');
    final accepted = strings('accepted');
    final answerIndex = (json['answerIndex'] as num?)?.toInt() ?? 0;
    final numeric = (json['numericAnswer'] as num?)?.toDouble();
    final prompt = '${json['prompt'] ?? ''}'.trim();
    if (prompt.isEmpty) {
      throw const FormatException('empty prompt');
    }
    switch (type) {
      case QuestionType.multipleChoice:
        if (options.length < 2 || answerIndex < 0 || answerIndex >= options.length) {
          throw const FormatException('bad options');
        }
      case QuestionType.trueFalse:
        if (answerIndex < 0 || answerIndex > 1) {
          throw const FormatException('bad answer');
        }
      case QuestionType.fillBlank:
      case QuestionType.code:
        if (accepted.isEmpty) throw const FormatException('no accepted');
      case QuestionType.numeric:
        if (numeric == null) throw const FormatException('no number');
      case QuestionType.ordering:
        if (options.length < 2) throw const FormatException('bad order');
      case QuestionType.matching:
        if (options.length < 2 || rights.length != options.length) {
          throw const FormatException('bad pairs');
        }
      case QuestionType.open:
        break;
    }
    return Question(
      id: id,
      subjectId: subjectId,
      topicId: topicId,
      type: type,
      difficulty: ((json['difficulty'] as num?)?.toInt() ?? 3).clamp(1, 5),
      prompt: prompt,
      explanation: '${json['explanation'] ?? ''}',
      options: type == QuestionType.trueFalse ? const ['Ճիշտ', 'Սխալ'] : options,
      rights: rights,
      answerIndex: answerIndex,
      accepted: accepted,
      numericAnswer: numeric,
      keywords: strings('keywords'),
      generated: generated,
    );
  }
}

class Topic {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.tip,
  });

  final String id;
  final String subjectId;
  final String title;

  /// Պարզ բացատրություն. ցուցադրվում է, երբ օգտատերը դժվարանում է։
  final String tip;
}

class LearnSubject {
  const LearnSubject({
    required this.id,
    required this.title,
    required this.group,
    required this.colorValue,
    required this.topics,
    this.codeLanguage,
  });

  final String id;
  final String title;
  final String group;
  final int colorValue;
  final List<Topic> topics;

  /// Օգտագործվում է AI հարցերի պրոմպտում։
  final String? codeLanguage;
}

// ---------------------------------------------------------------------------
// Օգտատեր և առաջընթաց
// ---------------------------------------------------------------------------

class LearnAccount {
  const LearnAccount({
    required this.id,
    required this.name,
    required this.salt,
    required this.hash,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String salt;
  final String hash;

  /// Ադմինը կարող է խմբագրել ուսումնական նյութերը և կառավարել ադմիններին։
  final bool isAdmin;

  LearnAccount copyWith({bool? isAdmin}) => LearnAccount(
    id: id,
    name: name,
    salt: salt,
    hash: hash,
    isAdmin: isAdmin ?? this.isAdmin,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'salt': salt,
    'hash': hash,
    'admin': isAdmin,
  };

  factory LearnAccount.fromJson(Map<String, dynamic> json) => LearnAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    salt: json['salt'] as String,
    hash: json['hash'] as String,
    isAdmin: json['admin'] == true,
  );
}

class TopicStats {
  TopicStats({
    this.answered = 0,
    this.correct = 0,
    this.mastery = 0,
    this.totalMs = 0,
    this.lastPracticed,
  });

  int answered;
  int correct;
  double mastery; // 0..1
  int totalMs;
  DateTime? lastPracticed;

  double get accuracy => answered == 0 ? 0 : correct / answered;
  int get averageSeconds => answered == 0 ? 0 : (totalMs / answered / 1000).round();

  Stage get stage {
    if (mastery >= 0.75) return Stage.advanced;
    if (mastery >= 0.4) return Stage.intermediate;
    return Stage.beginner;
  }

  void record({required bool correct, required int difficulty, required int ms}) {
    answered++;
    totalMs += ms;
    if (correct) {
      this.correct++;
      final target = math.min(1.0, 0.35 + 0.16 * difficulty);
      final delta = (target - mastery) * 0.25;
      if (delta > 0) mastery += delta;
    } else {
      mastery -= mastery * (0.30 - 0.03 * difficulty);
    }
    mastery = mastery.clamp(0.0, 1.0);
    lastPracticed = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'answered': answered,
    'correct': correct,
    'mastery': mastery,
    'totalMs': totalMs,
    'lastPracticed': lastPracticed?.toIso8601String(),
  };

  factory TopicStats.fromJson(Map<String, dynamic> json) => TopicStats(
    answered: (json['answered'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    mastery: (json['mastery'] as num?)?.toDouble() ?? 0,
    totalMs: (json['totalMs'] as num?)?.toInt() ?? 0,
    lastPracticed: json['lastPracticed'] == null
        ? null
        : DateTime.tryParse(json['lastPracticed'] as String),
  );
}

class SessionRecord {
  const SessionRecord({
    required this.date,
    required this.subjectId,
    required this.topicIds,
    required this.correct,
    required this.total,
    required this.xp,
  });

  final DateTime date;
  final String subjectId;
  final List<String> topicIds;
  final int correct;
  final int total;
  final int xp;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'subjectId': subjectId,
    'topicIds': topicIds,
    'correct': correct,
    'total': total,
    'xp': xp,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    date: DateTime.parse(json['date'] as String),
    subjectId: json['subjectId'] as String,
    topicIds: (json['topicIds'] as List<dynamic>).map((e) => '$e').toList(),
    correct: (json['correct'] as num).toInt(),
    total: (json['total'] as num).toInt(),
    xp: (json['xp'] as num?)?.toInt() ?? 0,
  );
}

class LearnProfile {
  LearnProfile({
    required this.userId,
    this.xp = 0,
    Set<String>? subjects,
    Map<String, TopicStats>? stats,
    Map<String, int>? mistakes,
    List<SessionRecord>? history,
    Set<String>? achievements,
    Set<String>? activityDays,
    this.hardCorrect = 0,
    this.lastSubjectId,
    this.lastTopicId,
  }) : subjects = subjects ?? <String>{},
       stats = stats ?? <String, TopicStats>{},
       mistakes = mistakes ?? <String, int>{},
       history = history ?? <SessionRecord>[],
       achievements = achievements ?? <String>{},
       activityDays = activityDays ?? <String>{};

  final String userId;
  int xp;
  final Set<String> subjects;

  /// Բանալի՝ topicId։
  final Map<String, TopicStats> stats;

  /// Բանալի՝ questionId, արժեք՝ ակտիվ սխալների քանակ (ճիշտ պատասխանից հետո նվազում է)։
  final Map<String, int> mistakes;
  final List<SessionRecord> history;
  final Set<String> achievements;
  final Set<String> activityDays;
  int hardCorrect;
  String? lastSubjectId;
  String? lastTopicId;

  TopicStats statsFor(String topicId) =>
      stats.putIfAbsent(topicId, TopicStats.new);

  TopicStats? peekStats(String topicId) => stats[topicId];

  int get level => levelForXp(xp);
  int get xpIntoLevel => xp - xpForLevel(level);
  int get xpForNextLevel => xpForLevel(level + 1) - xpForLevel(level);

  Stage get rank {
    if (level >= 8) return Stage.advanced;
    if (level >= 4) return Stage.intermediate;
    return Stage.beginner;
  }

  static int xpForLevel(int level) => 50 * (level - 1) * (level - 1);

  static int levelForXp(int xp) => math.sqrt(xp / 50).floor() + 1;

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int get streak {
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    if (!activityDays.contains(dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (activityDays.contains(dayKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'xp': xp,
    'subjects': subjects.toList(),
    'stats': stats.map((key, value) => MapEntry(key, value.toJson())),
    'mistakes': mistakes,
    'history': history.map((item) => item.toJson()).toList(),
    'achievements': achievements.toList(),
    'activityDays': activityDays.toList(),
    'hardCorrect': hardCorrect,
    'lastSubjectId': lastSubjectId,
    'lastTopicId': lastTopicId,
  };

  factory LearnProfile.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>? ?? const {};
    final rawMistakes = json['mistakes'] as Map<String, dynamic>? ?? const {};
    return LearnProfile(
      userId: json['userId'] as String,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      subjects: ((json['subjects'] as List<dynamic>?) ?? const [])
          .map((e) => '$e')
          .toSet(),
      stats: rawStats.map(
        (key, value) =>
            MapEntry(key, TopicStats.fromJson(value as Map<String, dynamic>)),
      ),
      mistakes: rawMistakes.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      history: ((json['history'] as List<dynamic>?) ?? const [])
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: ((json['achievements'] as List<dynamic>?) ?? const [])
          .map((e) => '$e')
          .toSet(),
      activityDays: ((json['activityDays'] as List<dynamic>?) ?? const [])
          .map((e) => '$e')
          .toSet(),
      hardCorrect: (json['hardCorrect'] as num?)?.toInt() ?? 0,
      lastSubjectId: json['lastSubjectId'] as String?,
      lastTopicId: json['lastTopicId'] as String?,
    );
  }
}
