import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'adaptive_engine.dart';
import 'content_store.dart';
import 'learn_catalog.dart';
import 'learn_models.dart';
import 'learn_repository.dart';
import 'question_source.dart';

class SessionReward {
  const SessionReward({
    required this.xpGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.achievements,
    required this.unlocked,
  });

  final int xpGained;
  final int levelBefore;
  final int levelAfter;
  final List<Achievement> achievements;

  /// Նոր բացված թեմաների և մակարդակների նկարագրություններ։
  final List<String> unlocked;

  bool get leveledUp => levelAfter > levelBefore;
}

class LearnController extends ChangeNotifier {
  LearnController(this._repository, {QuestionProvider? provider, Random? random})
    : provider = provider ?? QuestionProvider(),
      _random = random ?? Random();

  final LearnRepository _repository;
  final QuestionProvider provider;
  final Random _random;

  /// Ադմինի վահանակի մուտքի ֆիքսված տվյալները։ Վահանակ մտնել կարելի է ՄԻԱՅՆ
  /// այս անունով և գաղտնաբառով։ Փոխելու համար խմբագրեք այս երկու տողը։
  static const adminUsername = 'Admin_Panel_Access';
  static const adminPassword = 'Admin_Panel_123';
  static const _adminId = 'builtin-admin';

  var _accounts = <LearnAccount>[];
  LearnAccount? user;

  /// `true`՝ միայն ներկառուցված ադմինը կարող է մուտք գործել, սովորողները՝ ոչ։
  var adminOnlyLogin = false;

  /// Ինքնուրույն գրանցումը բաց է, եթե սովորողների մուտքը չի արգելված։
  bool get registrationOpen => !adminOnlyLogin;

  /// Կեղծ չլինելու համար ադմինի իրավունքը կախված է ոչ թե հաշվի դաշտից,
  /// այլ այն բանից, որ այս աշխատաշրջանը բացվել է ադմինի տվյալներով։
  var _adminSession = false;
  LearnProfile? profile;

  bool get signedIn => user != null && profile != null;
  bool get hasAccounts => _accounts.isNotEmpty;

  Future<void> init() async {
    final content = ContentStore.instance;
    content.reset();
    final savedContent = await _repository.loadContent();
    if (savedContent != null) content.loadFromJson(savedContent);

    final loaded = await _repository.loadAccounts();
    _accounts = loaded.accounts;
    adminOnlyLogin = loaded.adminOnly;
    // Ադմինի աշխատաշրջանը երբեք չի հիշվում՝ վահանակ մտնելու համար ամեն անգամ
    // պետք է մուտքագրել ադմինի տվյալները։
    final id = loaded.currentId;
    if (id != null) {
      for (final account in _accounts) {
        if (account.id == id && !adminOnlyLogin) {
          user = account;
          profile = await _repository.loadProfile(id);
          break;
        }
      }
    }
    notifyListeners();
  }

  // ----------------------------- Հաշիվ -----------------------------

  static String hashPassword(String salt, String password) {
    var digest = sha256.convert(utf8.encode('$salt:$password')).bytes;
    for (var i = 0; i < 3000; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Url.encode(digest);
  }

  String _newSalt() {
    final rng = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => rng.nextInt(256)));
  }

  Future<String?> register(String name, String password) async {
    if (!registrationOpen) {
      return 'Գրանցումը փակ է։ Նոր հաշիվ ստեղծում է ադմինը։';
    }
    final cleanName = name.trim();
    if (cleanName.length < 2) return 'Մուտքագրեք անուն (առնվազն 2 նիշ)։';
    if (_isReservedName(cleanName)) return 'Այս անունը վերապահված է։';
    if (password.length < 4) return 'Գաղտնաբառը պետք է ունենա առնվազն 4 նիշ։';
    final exists = _accounts.any((a) => a.name.toLowerCase() == cleanName.toLowerCase());
    if (exists) return 'Այս անունով հաշիվ արդեն կա։';
    final salt = _newSalt();
    final account = LearnAccount(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      salt: salt,
      hash: hashPassword(salt, password),
    );
    _accounts = [..._accounts, account];
    _adminSession = false;
    user = account;
    profile = LearnProfile(userId: account.id);
    try {
      await _repository.saveAccounts(_accounts, account.id, adminOnly: adminOnlyLogin);
      await _repository.saveProfile(profile!);
    } catch (e) {
      notifyListeners();
      return '$e';
    }
    notifyListeners();
    return null;
  }

  static bool _isReservedName(String name) =>
      name.trim().toLowerCase() == adminUsername.toLowerCase();

  /// Հաստատուն ժամանակով համեմատություն (չի բացահայտում, թե որտեղ է տարբերությունը)։
  static bool _sameText(String a, String b) {
    final x = sha256.convert(utf8.encode(a)).bytes;
    final y = sha256.convert(utf8.encode(b)).bytes;
    var diff = 0;
    for (var i = 0; i < x.length; i++) {
      diff |= x[i] ^ y[i];
    }
    return diff == 0;
  }

  Future<String?> login(String name, String password) async {
    if (_sameText(name.trim(), adminUsername) && _sameText(password, adminPassword)) {
      _adminSession = true;
      user = const LearnAccount(
        id: _adminId,
        name: adminUsername,
        salt: '',
        hash: '',
        isAdmin: true,
      );
      profile = await _repository.loadProfile(_adminId);
      notifyListeners();
      return null;
    }
    final cleanName = name.trim().toLowerCase();
    LearnAccount? found;
    for (final account in _accounts) {
      if (account.name.toLowerCase() == cleanName) found = account;
    }
    if (found == null || hashPassword(found.salt, password) != found.hash) {
      return 'Անունը կամ գաղտնաբառը սխալ է։';
    }
    if (adminOnlyLogin) {
      return 'Մուտքը թույլատրված է միայն ադմիններին։';
    }
    _adminSession = false;
    user = found;
    profile = await _repository.loadProfile(found.id);
    try {
      await _repository.saveAccounts(_accounts, found.id, adminOnly: adminOnlyLogin);
    } catch (_) {
      // Մուտքը աշխատում է նաև առանց հիշելու։
    }
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await _save();
    _adminSession = false;
    user = null;
    profile = null;
    try {
      await _repository.saveAccounts(_accounts, null, adminOnly: adminOnlyLogin);
    } catch (_) {
      // անտեսվում է
    }
    notifyListeners();
  }

  // ----------------------------- Առարկաներ -----------------------------

  Future<void> toggleSubject(String id) async {
    final p = profile;
    if (p == null) return;
    if (!p.subjects.remove(id)) p.subjects.add(id);
    notifyListeners();
    await _save();
  }

  List<LearnSubject> get selectedSubjects {
    final p = profile;
    if (p == null) return const [];
    return [for (final s in learnSubjects) if (p.subjects.contains(s.id)) s];
  }

  double subjectMastery(LearnSubject subject) {
    final p = profile;
    if (p == null || subject.topics.isEmpty) return 0;
    var sum = 0.0;
    for (final topic in subject.topics) {
      sum += p.peekStats(topic.id)?.mastery ?? 0;
    }
    return sum / subject.topics.length;
  }

  /// Վերջին թեման «Շարունակել» կոճակի համար։
  Topic? get continueTopic {
    final id = profile?.lastTopicId;
    return id == null ? null : topicById(id);
  }

  // ----------------------------- Ադմին -----------------------------

  static const _notAdmin = 'Այս գործողությունը հասանելի է միայն ադմինին։';

  bool get isAdmin => _adminSession && user?.id == _adminId;

  List<LearnAccount> get accounts => List.unmodifiable(_accounts);

  Future<String?> _persistContent() async {
    try {
      await _repository.saveContent(ContentStore.instance.toJson());
    } catch (e) {
      return e is StateError ? e.message : '$e';
    } finally {
      notifyListeners();
    }
    return null;
  }

  Future<String?> saveSubject({
    String? id,
    required String title,
    required String group,
    required int colorValue,
  }) async {
    if (!isAdmin) return _notAdmin;
    final cleanTitle = title.trim();
    final cleanGroup = group.trim();
    if (cleanTitle.isEmpty) return 'Մուտքագրեք առարկայի անունը։';
    if (cleanGroup.isEmpty) return 'Ընտրեք կամ մուտքագրեք խումբը։';
    final duplicate = learnSubjects.any(
      (s) => s.id != id && s.title.toLowerCase() == cleanTitle.toLowerCase(),
    );
    if (duplicate) return 'Այս անունով առարկա արդեն կա։';
    final store = ContentStore.instance;
    store.upsertSubject(LearnSubject(
      id: id ?? store.newId('s'),
      title: cleanTitle,
      group: cleanGroup,
      colorValue: colorValue,
      topics: const [],
    ));
    return _persistContent();
  }

  Future<String?> deleteSubject(String id) async {
    if (!isAdmin) return _notAdmin;
    ContentStore.instance.removeSubject(id);
    profile?.subjects.remove(id);
    await _save();
    return _persistContent();
  }

  Future<String?> saveTopic({
    String? id,
    required String subjectId,
    required String title,
    required String tip,
  }) async {
    if (!isAdmin) return _notAdmin;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'Մուտքագրեք թեմայի անունը։';
    final subject = subjectById(subjectId);
    if (subject == null) return 'Առարկան չի գտնվել։';
    final duplicate = subject.topics.any(
      (t) => t.id != id && t.title.toLowerCase() == cleanTitle.toLowerCase(),
    );
    if (duplicate) return 'Այս առարկայում նման թեմա արդեն կա։';
    final store = ContentStore.instance;
    store.upsertTopic(Topic(
      id: id ?? store.newId('$subjectId.t'),
      subjectId: subjectId,
      title: cleanTitle,
      tip: tip.trim(),
    ));
    return _persistContent();
  }

  Future<String?> deleteTopic(String topicId) async {
    if (!isAdmin) return _notAdmin;
    ContentStore.instance.removeTopic(topicId);
    return _persistContent();
  }

  Future<String?> moveTopic(String topicId, int delta) async {
    if (!isAdmin) return _notAdmin;
    ContentStore.instance.moveTopic(topicId, delta);
    return _persistContent();
  }

  /// Պահում է հարցը (նոր կամ խմբագրված)։ [question.id]-ն պետք է լինի ունիկալ։
  Future<String?> saveQuestion(Question question) async {
    if (!isAdmin) return _notAdmin;
    if (topicById(question.topicId) == null) return 'Թեման չի գտնվել։';
    ContentStore.instance.upsertQuestion(question);
    return _persistContent();
  }

  Future<String?> deleteQuestion(String topicId, String questionId) async {
    if (!isAdmin) return _notAdmin;
    ContentStore.instance.removeQuestion(topicId, questionId);
    return _persistContent();
  }

  /// Միացնում/անջատում է «միայն ադմինները կարող են մուտք գործել» ռեժիմը։
  Future<String?> setAdminOnlyLogin(bool value) async {
    if (!isAdmin) return _notAdmin;
    adminOnlyLogin = value;
    try {
      await _repository.saveAccounts(_accounts, _adminSession ? null : user?.id, adminOnly: adminOnlyLogin);
    } catch (e) {
      notifyListeners();
      return e is StateError ? e.message : '$e';
    }
    notifyListeners();
    return null;
  }

  /// Ադմինը ստեղծում է հաշիվ՝ առանց ինքը դուրս գալու։
  Future<String?> addAccount(String name, String password) async {
    if (!isAdmin) return _notAdmin;
    final cleanName = name.trim();
    if (cleanName.length < 2) return 'Մուտքագրեք անուն (առնվազն 2 նիշ)։';
    if (_isReservedName(cleanName)) return 'Այս անունը վերապահված է։';
    if (password.length < 4) return 'Գաղտնաբառը պետք է ունենա առնվազն 4 նիշ։';
    if (_accounts.any((a) => a.name.toLowerCase() == cleanName.toLowerCase())) {
      return 'Այս անունով հաշիվ արդեն կա։';
    }
    final salt = _newSalt();
    final account = LearnAccount(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      salt: salt,
      hash: hashPassword(salt, password),
    );
    _accounts = [..._accounts, account];
    try {
      await _repository.saveAccounts(_accounts, _adminSession ? null : user?.id, adminOnly: adminOnlyLogin);
    } catch (e) {
      notifyListeners();
      return e is StateError ? e.message : '$e';
    }
    notifyListeners();
    return null;
  }

  /// Վերադարձնում է ստանդարտ նյութերը՝ ջնջելով ադմինի բոլոր փոփոխությունները։
  Future<String?> resetContent() async {
    if (!isAdmin) return _notAdmin;
    ContentStore.instance.reset();
    try {
      await _repository.deleteContent();
    } catch (e) {
      notifyListeners();
      return e is StateError ? e.message : '$e';
    }
    notifyListeners();
    return null;
  }

  // ----------------------------- Դասեր -----------------------------

  Future<LessonSession> startTopic(Topic topic, Stage stage) async {
    final p = profile!;
    final stats = p.peekStats(topic.id);
    final weak = stats != null && stats.answered >= 5 && stats.mastery < 0.4;
    final pool = await provider.poolFor(
      topic,
      minDifficulty: stage.minDifficulty,
      maxDifficulty: stage.maxDifficulty,
      weakness: weak ? topic.title : null,
    );
    return LessonSession(
      subject: subjectById(topic.subjectId)!,
      topics: [topic],
      stage: stage,
      pool: pool,
      profile: p,
      startDifficulty: Unlocks.startDifficulty(stats?.mastery ?? 0, stage),
      random: _random,
    );
  }

  /// Խելացի կրկնություն՝ կենտրոնանում է դեռ լիարժեք չյուրացված թեմաների վրա։
  Future<LessonSession> startSmart(LearnSubject subject) async {
    final p = profile!;
    if (subject.topics.isEmpty) throw StateError('Առարկան թեմաներ չունի։');
    final topics = Unlocks.weakTopics(p, subject);
    var stage = p.peekStats(topics.first.id)?.stage ?? Stage.beginner;
    while (stage != Stage.beginner && !Unlocks.stageUnlocked(p, topics.first.id, stage)) {
      stage = Stage.values[stage.index - 1];
    }
    final pool = <Question>[];
    var mastery = 0.0;
    for (final topic in topics) {
      final stats = p.peekStats(topic.id);
      mastery += stats?.mastery ?? 0;
      pool.addAll(await provider.poolFor(
        topic,
        minDifficulty: stage.minDifficulty,
        maxDifficulty: stage.maxDifficulty,
        weakness: topic.title,
      ));
    }
    mastery /= topics.length;
    return LessonSession(
      subject: subject,
      topics: topics,
      stage: stage,
      pool: pool,
      profile: p,
      startDifficulty: Unlocks.startDifficulty(mastery, stage),
      random: _random,
    );
  }

  /// Գրանցում է դասի արդյունքները՝ XP, յուրացում, սխալներ, ձեռքբերումներ։
  Future<SessionReward> finish(LessonSession session) async {
    final p = profile!;
    final summary = session.summary();
    final levelBefore = p.level;
    final unlockedBefore = Unlocks.snapshot(p);

    for (final answer in summary.answers) {
      p.statsFor(answer.topicId).record(
        correct: answer.correct,
        difficulty: answer.difficulty,
        ms: answer.ms,
      );
      if (answer.correct) {
        final left = (p.mistakes[answer.questionId] ?? 0) - 1;
        if (left > 0) {
          p.mistakes[answer.questionId] = left;
        } else {
          p.mistakes.remove(answer.questionId);
        }
        if (!answer.isRetry && answer.difficulty >= 5) p.hardCorrect++;
      } else {
        p.mistakes[answer.questionId] = min(3, (p.mistakes[answer.questionId] ?? 0) + 1);
      }
    }

    if (summary.total > 0) {
      p.xp += summary.xp;
      p.activityDays.add(LearnProfile.dayKey(DateTime.now()));
      p.history.add(SessionRecord(
        date: DateTime.now(),
        subjectId: summary.subjectId,
        topicIds: summary.topicIds,
        correct: summary.correct,
        total: summary.total,
        xp: summary.xp,
      ));
      if (p.history.length > 60) p.history.removeRange(0, p.history.length - 60);
      p.subjects.add(summary.subjectId);
      p.lastSubjectId = summary.subjectId;
      p.lastTopicId = summary.topicIds.first;
    }

    final newIds = evaluateAchievements(p, session: summary);
    p.achievements.addAll(newIds);

    final unlockedAfter = Unlocks.snapshot(p);
    final unlockedLabels = <String>[];
    for (final key in unlockedAfter.difference(unlockedBefore)) {
      final parts = key.split(':');
      final topic = topicById(parts[1]);
      if (topic == null) continue;
      if (parts[0] == 'topic') {
        unlockedLabels.add('Նոր թեմա՝ ${topic.title}');
      } else {
        final stage = Stage.values.firstWhere((s) => s.name == parts[2]);
        if (stage != Stage.beginner) {
          unlockedLabels.add('${topic.title}՝ ${stage.label} մակարդակ');
        }
      }
    }

    await _save();
    notifyListeners();
    return SessionReward(
      xpGained: summary.xp,
      levelBefore: levelBefore,
      levelAfter: p.level,
      achievements: [for (final id in newIds) ?achievementById(id)],
      unlocked: unlockedLabels,
    );
  }

  Future<void> _save() async {
    final p = profile;
    if (p == null) return;
    try {
      await _repository.saveProfile(p);
    } catch (_) {
      // Պահպանման սխալը չպետք է խանգարի ուսուցմանը։
    }
  }
}
