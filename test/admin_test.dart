import 'dart:io';
import 'dart:math';

import 'package:dart_project/learn/content_store.dart';
import 'package:dart_project/learn/learn_catalog.dart';
import 'package:dart_project/learn/learn_controller.dart';
import 'package:dart_project/learn/learn_models.dart';
import 'package:dart_project/learn/learn_repository.dart';
import 'package:dart_project/learn/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

LearnController _controller(Directory dir) =>
    LearnController(LearnRepository(directory: dir), random: Random(1));

Future<void> _loginAdmin(LearnController c) async {
  expect(await c.login(LearnController.adminUsername, LearnController.adminPassword), isNull);
}

Question _numeric(String id, String subjectId, String topicId, String prompt, double answer) {
  return Question(
    id: id,
    subjectId: subjectId,
    topicId: topicId,
    type: QuestionType.numeric,
    difficulty: 2,
    prompt: prompt,
    explanation: '',
    numericAnswer: answer,
  );
}

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('admin');
    ContentStore.instance.reset();
  });

  tearDown(() => ContentStore.instance.reset());

  test('admin panel opens only with the fixed username and password', () async {
    final c = _controller(dir);
    await c.init();
    expect(LearnController.adminUsername, 'Admin_Panel_Access');
    expect(LearnController.adminPassword, 'Admin_Panel_123');

    for (final attempt in [
      ['Admin_Panel_Access', 'wrong'],
      ['Admin_Panel_Access', 'admin_panel_123'],
      ['Admin_Panel_Access', ''],
      ['Someone', 'Admin_Panel_123'],
      ['', 'Admin_Panel_123'],
    ]) {
      expect(await c.login(attempt[0], attempt[1]), isNotNull, reason: '$attempt');
      expect(c.isAdmin, isFalse, reason: '$attempt');
      expect(c.signedIn, isFalse, reason: '$attempt');
    }

    await _loginAdmin(c);
    expect(c.isAdmin, isTrue);
    expect(c.signedIn, isTrue);
    await c.logout();
    expect(c.isAdmin, isFalse);
    expect(c.signedIn, isFalse);
  });

  test('registered accounts are never admins and cannot take the admin name', () async {
    final c = _controller(dir);
    await c.init();
    expect(await c.register('Ani', 'secret'), isNull); // առաջին հաշիվը նույնպես սովորող է
    expect(c.isAdmin, isFalse);
    await c.logout();

    expect(await c.register('Admin_Panel_Access', 'secret'), isNotNull);
    expect(await c.register('admin_panel_access', 'secret'), isNotNull);
    expect(c.accounts.map((a) => a.name), ['Ani']);
  });

  test('an old account file with an admin flag does not grant the panel', () async {
    final repo = LearnRepository(directory: dir);
    await repo.saveAccounts(const [
      LearnAccount(id: 'u1', name: 'Old', salt: 's', hash: 'h', isAdmin: true),
    ], 'u1');
    final c = LearnController(repo, random: Random(1));
    await c.init();
    expect(c.isAdmin, isFalse);
    expect(await c.saveSubject(title: 'X', group: groupMath, colorValue: 0xFF000000), isNotNull);
  });

  test('the admin session is not remembered after a restart', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);
    expect(await c.setAdminOnlyLogin(false), isNull);

    final again = _controller(dir);
    await again.init();
    expect(again.isAdmin, isFalse);
    expect(again.signedIn, isFalse);
  });

  test('non-admin cannot change content', () async {
    final c = _controller(dir);
    await c.init();
    await c.register('Bob', 'secret');
    expect(c.isAdmin, isFalse);
    final before = learnSubjects.length;
    expect(
      await c.saveSubject(title: 'Test', group: groupMath, colorValue: 0xFF000000),
      isNotNull,
    );
    expect(await c.deleteTopic('math.logic'), isNotNull);
    expect(learnSubjects.length, before);
    expect(topicById('math.logic'), isNotNull);
  });

  test('admin adds subject, topic and question and they survive a restart', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);

    expect(
      await c.saveSubject(title: 'Կոտորակներ', group: groupMath, colorValue: 0xFF1565C0),
      isNull,
    );
    final subject = learnSubjects.firstWhere((s) => s.title == 'Կոտորակներ');
    expect(
      await c.saveTopic(subjectId: subject.id, title: 'Գումարում', tip: 'Ընդհանուր հայտարար'),
      isNull,
    );
    final topic = subjectById(subject.id)!.topics.single;
    expect(
      await c.saveQuestion(_numeric('q-test', subject.id, topic.id, '1/2 + 1/2 = ?', 1)),
      isNull,
    );
    expect(QuestionBank.forTopic(topic.id).map((q) => q.id), ['q-test']);

    // Նոր կոնտրոլերը նույն պանակից պետք է տեսնի նույն նյութերը։
    ContentStore.instance.reset();
    expect(subjectById(subject.id), isNull);
    final again = _controller(dir);
    await again.init();
    expect(subjectById(subject.id)?.title, 'Կոտորակներ');
    expect(topicById(topic.id)?.tip, 'Ընդհանուր հայտարար');
    final loaded = QuestionBank.forTopic(topic.id).single;
    expect(loaded.prompt, '1/2 + 1/2 = ?');
    expect(loaded.check('1'), isTrue);
    expect(loaded.generated, isFalse);
  });

  test('admin edits and deletes built-in math content', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);

    final questions = QuestionBank.forTopic('math.arith');
    final first = questions.first;
    expect(await c.deleteQuestion('math.arith', first.id), isNull);
    expect(QuestionBank.forTopic('math.arith').length, questions.length - 1);
    expect(QuestionBank.forTopic('math.arith').any((q) => q.id == first.id), isFalse);

    final edited = _numeric(questions[1].id, 'math', 'math.arith', 'Հաշվեք՝ 2 + 2', 4);
    expect(await c.saveQuestion(edited), isNull);
    expect(
      QuestionBank.forTopic('math.arith').firstWhere((q) => q.id == edited.id).prompt,
      'Հաշվեք՝ 2 + 2',
    );

    expect(
      await c.saveTopic(id: 'math.arith', subjectId: 'math', title: 'Թվաբանություն+', tip: 'նոր'),
      isNull,
    );
    expect(topicById('math.arith')!.title, 'Թվաբանություն+');

    expect(await c.deleteTopic('math.logic'), isNull);
    expect(topicById('math.logic'), isNull);
    expect(QuestionBank.forTopic('math.logic'), isEmpty);

    // Ներկառուցված ցանկը չի փոխվում։
    expect(QuestionBank.all.any((q) => q.id == first.id), isTrue);
  });

  test('topics can be reordered', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);
    final before = subjectById('math')!.topics.map((t) => t.id).toList();
    expect(await c.moveTopic(before[1], -1), isNull);
    final after = subjectById('math')!.topics.map((t) => t.id).toList();
    expect(after[0], before[1]);
    expect(after[1], before[0]);
  });

  test('reset restores built-in content', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);
    await c.deleteTopic('math.logic');
    final file = File('${dir.path}${Platform.pathSeparator}${LearnRepository.contentFile}');
    expect(file.existsSync(), isTrue);

    expect(await c.resetContent(), isNull);
    expect(topicById('math.logic'), isNotNull);
    expect(QuestionBank.forTopic('math.logic'), isNotEmpty);
    expect(file.existsSync(), isFalse);
  });

  test('subject with no topics does not break smart review', () async {
    final c = _controller(dir);
    await c.init();
    await _loginAdmin(c);
    await c.saveSubject(title: 'Դատարկ', group: 'Նոր խումբ', colorValue: 0xFF000000);
    final subject = learnSubjects.firstWhere((s) => s.title == 'Դատարկ');
    expect(learnGroups, contains('Նոր խումբ'));
    expect(c.startSmart(subject), throwsStateError);
  });

  test('students are blocked only while the admin-only switch is on', () async {
    final c = _controller(dir);
    await c.init();
    expect(c.adminOnlyLogin, isFalse);
    expect(await c.register('Bob', 'secret'), isNull);
    await c.logout();

    await _loginAdmin(c);
    expect(await c.setAdminOnlyLogin(true), isNull);
    expect(await c.addAccount('Cid', 'secret'), isNull);
    expect(await c.addAccount('Admin_Panel_Access', 'secret'), isNotNull);
    expect(c.user!.name, LearnController.adminUsername); // ադմինը մնում է իր հաշվում
    await c.logout();

    expect(await c.register('Dan', 'secret'), isNotNull); // գրանցումը փակ է
    expect(await c.login('Bob', 'secret'), isNotNull);
    expect(c.signedIn, isFalse);

    final again = _controller(dir);
    await again.init();
    expect(again.adminOnlyLogin, isTrue);
    expect(await again.login('Cid', 'secret'), isNotNull);
    expect(await again.login(LearnController.adminUsername, LearnController.adminPassword), isNull);
    expect(await again.setAdminOnlyLogin(false), isNull);
    await again.logout();
    expect(await again.login('Cid', 'secret'), isNull);
    expect(again.isAdmin, isFalse);
    expect(await again.addAccount('Eve', 'secret'), isNotNull); // ոչ ադմինը չի կարող
  });
}
