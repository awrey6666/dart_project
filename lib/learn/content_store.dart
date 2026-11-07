import 'learn_catalog.dart';
import 'learn_models.dart';
import 'question_bank.dart';

/// Ուսումնական նյութերի ընթացիկ վիճակը՝ առարկաներ, թեմաներ և հարցեր։
///
/// Սկզբում այն համընկնում է ներկառուցված կատալոգի ([builtinSubjects]) և հարցերի
/// ([QuestionBank.all]) հետ։ Երբ ադմինը ինչ-որ բան փոխում է, ամբողջ վիճակը
/// պահվում է JSON ֆայլում (տե՛ս `LearnRepository.saveContent`) և հաջորդ
/// գործարկման ժամանակ բեռնվում է այնտեղից։ Այսինքն՝ փոփոխությունից հետո ֆայլը
/// դառնում է «ճշմարտության աղբյուր», իսկ ներկառուցվածը՝ միայն սկզբնական տարբերակ։
class ContentStore {
  ContentStore._();

  static final ContentStore instance = ContentStore._();

  static const formatVersion = 1;

  List<LearnSubject> _subjects = List<LearnSubject>.of(builtinSubjects);
  Map<String, List<Question>>? _questions;

  /// `true`՝ եթե ադմինը արդեն փոփոխել է նյութերը (այսինքն՝ ունենք պահված ֆայլ)։
  bool customized = false;

  List<LearnSubject> get subjects => _subjects;

  /// Խմբերը՝ նախ ստանդարտ հերթականությամբ (եթե օգտագործվում են), հետո նորերը։
  List<String> get groups {
    final used = <String>{for (final s in _subjects) s.group};
    return [
      for (final g in defaultGroups)
        if (used.contains(g)) g,
      for (final g in used)
        if (!defaultGroups.contains(g)) g,
    ];
  }

  Map<String, List<Question>> get _byTopic =>
      _questions ??= _groupQuestions(QuestionBank.all);

  static Map<String, List<Question>> _groupQuestions(Iterable<Question> all) {
    final map = <String, List<Question>>{};
    for (final q in all) {
      map.putIfAbsent(q.topicId, () => <Question>[]).add(q);
    }
    return map;
  }

  /// Վերադարձնում է ստանդարտ նյութերը և մոռանում ադմինի փոփոխությունները։
  void reset() {
    _subjects = List<LearnSubject>.of(builtinSubjects);
    _questions = null;
    customized = false;
  }

  /// Նոր յուրահատուկ նույնացուցիչ։ [prefix]-ը օգնում է կարդալ ֆայլը։
  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  // ----------------------------- Հարցեր -----------------------------

  List<Question> questionsFor(String topicId) =>
      List<Question>.of(_byTopic[topicId] ?? const <Question>[]);

  int questionCount(String topicId) => _byTopic[topicId]?.length ?? 0;

  int questionCountForSubject(LearnSubject subject) {
    var sum = 0;
    for (final topic in subject.topics) {
      sum += questionCount(topic.id);
    }
    return sum;
  }

  /// Ավելացնում է նոր հարց կամ փոխարինում նույն id-ով գոյություն ունեցողին։
  void upsertQuestion(Question question) {
    final list = _byTopic.putIfAbsent(question.topicId, () => <Question>[]);
    final index = list.indexWhere((q) => q.id == question.id);
    if (index >= 0) {
      list[index] = question;
    } else {
      list.add(question);
    }
    customized = true;
  }

  void removeQuestion(String topicId, String questionId) {
    _byTopic[topicId]?.removeWhere((q) => q.id == questionId);
    customized = true;
  }

  // ----------------------------- Թեմաներ -----------------------------

  /// Ավելացնում է թեման իր առարկայի վերջում կամ թարմացնում գոյություն ունեցողին։
  /// Վերադարձնում է `false`, եթե առարկան գոյություն չունի։
  bool upsertTopic(Topic topic) {
    final index = _subjects.indexWhere((s) => s.id == topic.subjectId);
    if (index < 0) return false;
    final subject = _subjects[index];
    final topics = List<Topic>.of(subject.topics);
    final at = topics.indexWhere((t) => t.id == topic.id);
    if (at >= 0) {
      topics[at] = topic;
    } else {
      topics.add(topic);
    }
    _replaceSubject(index, subject, topics);
    customized = true;
    return true;
  }

  void removeTopic(String topicId) {
    for (var i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      if (!subject.topics.any((t) => t.id == topicId)) continue;
      _replaceSubject(
        i,
        subject,
        [for (final t in subject.topics) if (t.id != topicId) t],
      );
      break;
    }
    _byTopic.remove(topicId);
    customized = true;
  }

  /// Տեղափոխում է թեման վերև (`delta = -1`) կամ ներքև (`delta = 1`)։
  /// Թեմաները բացվում են հաջորդաբար, ուստի հերթականությունը կարևոր է։
  void moveTopic(String topicId, int delta) {
    for (var i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      final from = subject.topics.indexWhere((t) => t.id == topicId);
      if (from < 0) continue;
      final to = from + delta;
      if (to < 0 || to >= subject.topics.length) return;
      final topics = List<Topic>.of(subject.topics);
      final moved = topics.removeAt(from);
      topics.insert(to, moved);
      _replaceSubject(i, subject, topics);
      customized = true;
      return;
    }
  }

  void _replaceSubject(int index, LearnSubject old, List<Topic> topics) {
    final next = List<LearnSubject>.of(_subjects);
    next[index] = LearnSubject(
      id: old.id,
      title: old.title,
      group: old.group,
      colorValue: old.colorValue,
      topics: topics,
      codeLanguage: old.codeLanguage,
    );
    _subjects = next;
  }

  // ----------------------------- Առարկաներ -----------------------------

  /// Ավելացնում է նոր առարկա կամ թարմացնում գոյություն ունեցողի վերնագիրը,
  /// խումբը և գույնը (թեմաները չեն փոխվում, եթե առարկան արդեն կա)։
  void upsertSubject(LearnSubject subject) {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    final next = List<LearnSubject>.of(_subjects);
    if (index >= 0) {
      final old = _subjects[index];
      next[index] = LearnSubject(
        id: old.id,
        title: subject.title,
        group: subject.group,
        colorValue: subject.colorValue,
        topics: old.topics,
        codeLanguage: old.codeLanguage,
      );
    } else {
      next.add(subject);
    }
    _subjects = next;
    customized = true;
  }

  void removeSubject(String subjectId) {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index < 0) return;
    for (final topic in _subjects[index].topics) {
      _byTopic.remove(topic.id);
    }
    _subjects = [
      for (final s in _subjects)
        if (s.id != subjectId) s,
    ];
    customized = true;
  }

  // ----------------------------- Պահպանում -----------------------------

  Map<String, dynamic> toJson() => {
    'version': formatVersion,
    'subjects': [
      for (final s in _subjects)
        {
          'id': s.id,
          'title': s.title,
          'group': s.group,
          'color': s.colorValue,
          'codeLanguage': s.codeLanguage,
          'topics': [
            for (final t in s.topics)
              {'id': t.id, 'title': t.title, 'tip': t.tip},
          ],
        },
    ],
    'questions': [
      for (final s in _subjects)
        for (final t in s.topics)
          for (final q in _byTopic[t.id] ?? const <Question>[]) q.toJson(),
    ],
  };

  /// Բեռնում է պահված նյութերը։ Վնասված տվյալի դեպքում վիճակը չի փոխվում։
  bool loadFromJson(Map<String, dynamic> json) {
    try {
      final subjects = <LearnSubject>[];
      final seenSubjects = <String>{};
      final seenTopics = <String>{};
      for (final raw in json['subjects'] as List<dynamic>) {
        final s = raw as Map<String, dynamic>;
        final id = s['id'] as String;
        if (!seenSubjects.add(id)) continue;
        final topics = <Topic>[];
        for (final rawTopic in s['topics'] as List<dynamic>) {
          final t = rawTopic as Map<String, dynamic>;
          final topicId = t['id'] as String;
          if (!seenTopics.add(topicId)) continue;
          topics.add(Topic(
            id: topicId,
            subjectId: id,
            title: t['title'] as String,
            tip: (t['tip'] as String?) ?? '',
          ));
        }
        subjects.add(LearnSubject(
          id: id,
          title: s['title'] as String,
          group: s['group'] as String,
          colorValue: (s['color'] as num).toInt(),
          topics: topics,
          codeLanguage: s['codeLanguage'] as String?,
        ));
      }

      final bySubject = {for (final s in subjects) s.id: s};
      final questions = <Question>[];
      final seenQuestions = <String>{};
      for (final raw in (json['questions'] as List<dynamic>? ?? const [])) {
        try {
          final q = raw as Map<String, dynamic>;
          final topicId = q['topicId'] as String;
          final subjectId = q['subjectId'] as String;
          final subject = bySubject[subjectId];
          if (subject == null || !subject.topics.any((t) => t.id == topicId)) {
            continue;
          }
          final id = q['id'] as String;
          if (!seenQuestions.add(id)) continue;
          questions.add(Question.fromJson(
            q,
            id: id,
            subjectId: subjectId,
            topicId: topicId,
            generated: false,
          ));
        } catch (_) {
          // Վնասված մեկ հարցը չպետք է խանգարի մնացածին։
        }
      }

      _subjects = subjects;
      _questions = _groupQuestions(questions);
      customized = true;
      return true;
    } catch (_) {
      return false;
    }
  }
}
