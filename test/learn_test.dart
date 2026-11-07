import 'dart:io';
import 'dart:math';

import 'package:dart_project/learn/adaptive_engine.dart';
import 'package:dart_project/learn/learn_catalog.dart';
import 'package:dart_project/learn/learn_controller.dart';
import 'package:dart_project/learn/learn_models.dart';
import 'package:dart_project/learn/learn_repository.dart';
import 'package:dart_project/learn/question_bank.dart';
import 'package:dart_project/learn/question_source.dart';
import 'package:flutter_test/flutter_test.dart';

LearnController _controller([Directory? dir]) => LearnController(
  LearnRepository(directory: dir ?? Directory.systemTemp.createTempSync('learn')),
  random: Random(1),
);

void main() {
  test('every bank question belongs to a known topic and has unique id', () {
    final ids = <String>{};
    for (final q in QuestionBank.all) {
      expect(topicById(q.topicId), isNotNull, reason: q.id);
      expect(ids.add(q.id), isTrue, reason: q.id);
    }
    for (final subject in learnSubjects) {
      for (final topic in subject.topics) {
        expect(QuestionBank.forTopic(topic.id), isNotEmpty, reason: topic.id);
      }
    }
  });

  test('question checking by type', () {
    final order = QuestionBank.all.firstWhere((q) => q.type == QuestionType.ordering);
    expect(order.check(List<int>.generate(order.options.length, (i) => i)), isTrue);
    expect(order.check(List<int>.generate(order.options.length, (i) => order.options.length - 1 - i)), isFalse);
    final numeric = QuestionBank.all.firstWhere((q) => q.type == QuestionType.numeric);
    expect(numeric.check('${numeric.numericAnswer}'), isTrue);
    expect(numeric.check('abc'), isFalse);
  });

  test('math generator produces solvable questions', () {
    final r = Random(3);
    for (final topic in ['math.arith', 'math.algebra', 'math.geometry', 'math.logic']) {
      for (var d = 1; d <= 5; d++) {
        final list = MathGenerator.make(topic, d, 5, r);
        expect(list.length, 5);
        for (final q in list) {
          expect(q.check('${q.numericAnswer}'), isTrue);
        }
      }
    }
  });

  test('difficulty rises after correct answers and falls after mistakes', () async {
    final c = _controller();
    expect(await c.register('Ani', 'secret'), isNull);
    final topic = topicById('math.arith')!;
    final up = await c.startTopic(topic, Stage.intermediate);
    final start = up.difficulty;
    for (var i = 0; i < 3; i++) {
      final q = up.next()!;
      up.submit(q.numericAnswer == null ? null : '${q.numericAnswer}', 1000);
    }
    expect(start, 2);
    expect(up.difficulty, inInclusiveRange(1, 5));

    final down = await c.startTopic(topic, Stage.intermediate);
    final before = down.difficulty;
    down.next();
    down.submit('wrong', 1000);
    down.next();
    final outcome = down.submit('wrong', 1000);
    expect(outcome.needsHelp, isTrue);
    expect(down.difficulty, lessThan(before));
  });

  test('accounts are separate and progress persists', () async {
    final dir = Directory.systemTemp.createTempSync('learn');
    final c = _controller(dir);
    expect(await c.register('Ani', 'secret'), isNull);
    expect(await c.register('ani', 'other1'), isNotNull);
    final session = await c.startTopic(topicById('dart.vars')!, Stage.beginner);
    while (session.next() != null) {
      session.submit(null, 500);
    }
    final reward = await c.finish(session);
    expect(reward.xpGained, greaterThanOrEqualTo(0));
    await c.logout();
    expect(await c.login('Ani', 'bad'), isNotNull);

    final again = _controller(dir);
    await again.init();
    expect(again.signedIn, isFalse);
    expect(await again.login('Ani', 'secret'), isNull);
    expect(again.profile!.history, isNotEmpty);
    expect(await again.register('Vah', 'abcd'), isNull);
    expect(again.profile!.history, isEmpty);
  });
}
