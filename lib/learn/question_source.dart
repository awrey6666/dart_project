import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'learn_catalog.dart';
import 'learn_models.dart';
import 'question_bank.dart';

/// Հարցերի աղբյուր (AI կամ այլ գեներատոր)։
abstract class QuestionSource {
  Future<List<Question>> generate({
    required LearnSubject subject,
    required Topic topic,
    required int minDifficulty,
    required int maxDifficulty,
    required int count,
    String? weakness,
  });
}

/// Անվերջ նոր մաթեմատիկական հարցեր՝ պարամետրերով գեներացվող։
class MathGenerator {
  const MathGenerator._();

  static List<Question> make(String topicId, int difficulty, int count, Random r) {
    final out = <Question>[];
    for (var i = 0; i < count; i++) {
      final q = _one(topicId, difficulty.clamp(1, 5), r);
      if (q != null) out.add(q);
    }
    return out;
  }

  static Question _build(
    String topicId,
    int d,
    Random r,
    String prompt,
    num answer,
    String why,
  ) {
    return Question(
      id: 'gen.$topicId.d$d.${r.nextInt(1 << 30)}',
      subjectId: 'math',
      topicId: topicId,
      type: QuestionType.numeric,
      difficulty: d,
      prompt: prompt,
      numericAnswer: answer.toDouble(),
      explanation: why,
      generated: true,
    );
  }

  static String _seq(List<int> items) =>
      'Շարունակեք շարքը՝ ${items.join(', ')}, ?';

  static Question? _one(String topic, int d, Random r) {
    switch (topic) {
      case 'math.arith':
        return _arith(topic, d, r);
      case 'math.algebra':
        return _algebra(topic, d, r);
      case 'math.geometry':
        return _geometry(topic, d, r);
      case 'math.logic':
        return _logic(topic, d, r);
    }
    return null;
  }

  static Question _arith(String t, int d, Random r) {
    switch (d) {
      case 1:
        final a = 10 + r.nextInt(50);
        final b = 10 + r.nextInt(40);
        if (r.nextBool()) {
          return _build(t, d, r, 'Հաշվեք՝ $a + $b', a + b, '$a + $b = ${a + b}։');
        }
        final x = max(a, b);
        final y = min(a, b);
        return _build(t, d, r, 'Հաշվեք՝ $x − $y', x - y, '$x − $y = ${x - y}։');
      case 2:
        final a = 6 + r.nextInt(10);
        final b = 6 + r.nextInt(10);
        return _build(t, d, r, 'Հաշվեք՝ $a × $b', a * b, '$a · $b = ${a * b}։');
      case 3:
        final a = 7 + r.nextInt(13);
        final b = 3 + r.nextInt(7);
        final c = 10 + r.nextInt(90);
        return _build(t, d, r, 'Հաշվեք՝ $a × $b + $c', a * b + c,
            'Սկզբում բազմապատկում՝ ${a * b}, հետո գումարում՝ ${a * b + c}։');
      case 4:
        const percents = [10, 15, 20, 25, 30, 40, 60, 75];
        final p = percents[r.nextInt(percents.length)];
        final n = 20 * (2 + r.nextInt(19));
        return _build(t, d, r, 'Գտեք $n թվի $p%-ը։', n * p / 100,
            '$n · $p / 100 = ${n * p / 100}։');
      default:
        final a = 3 + r.nextInt(8);
        final b = 2 + r.nextInt(8);
        final c = 2 + r.nextInt(8);
        final e = 2 + r.nextInt(6);
        final dd = e * (2 + r.nextInt(8));
        final answer = (a + b) * c - dd ~/ e;
        return _build(t, d, r, 'Հաշվեք՝ ($a + $b) × $c − $dd ÷ $e', answer,
            'Փակագծեր՝ ${a + b}, բազմապատկում՝ ${(a + b) * c}, բաժանում՝ ${dd ~/ e}, արդյունք՝ $answer։');
    }
  }

  static Question _algebra(String t, int d, Random r) {
    switch (d) {
      case 1:
        final x = 1 + r.nextInt(20);
        final b = 1 + r.nextInt(20);
        return _build(t, d, r, 'Լուծեք՝ x + $b = ${x + b}։ Գտեք x-ը։', x, 'x = ${x + b} − $b = $x։');
      case 2:
        final a = 2 + r.nextInt(8);
        final x = 2 + r.nextInt(11);
        return _build(t, d, r, 'Լուծեք՝ ${a}x = ${a * x}։ Գտեք x-ը։', x, 'x = ${a * x} / $a = $x։');
      case 3:
        final a = 2 + r.nextInt(8);
        final x = 1 + r.nextInt(12);
        final b = 1 + r.nextInt(20);
        return _build(t, d, r, 'Լուծեք՝ ${a}x + $b = ${a * x + b}։ Գտեք x-ը։', x,
            '${a}x = ${a * x}, ուստի x = $x։');
      case 4:
        for (var i = 0; i < 30; i++) {
          final x = 2 + r.nextInt(9);
          final a = 4 + r.nextInt(6);
          final c = 1 + r.nextInt(a - 1);
          final b = 1 + r.nextInt(10);
          final dd = (a - c) * x - b;
          if (dd <= 0) continue;
          return _build(t, d, r, 'Լուծեք՝ ${a}x − $b = ${c}x + $dd։ Գտեք x-ը։', x,
              '${a - c}x = ${b + dd}, ուստի x = $x։');
        }
        return _build(t, d, r, 'Լուծեք՝ 5x − 2 = 2x + 7։ Գտեք x-ը։', 3, '3x = 9, x = 3։');
      default:
        if (r.nextBool()) {
          final x = 5 + r.nextInt(11);
          final k = 1 + r.nextInt(30);
          return _build(t, d, r, 'Լուծեք՝ x² + $k = ${x * x + k} (x > 0)։ Գտեք x-ը։', x,
              'x² = ${x * x}, x > 0, ուստի x = $x։');
        }
        final a = 2 + r.nextInt(5);
        final x = 6 + r.nextInt(10);
        final b = 1 + r.nextInt(5);
        return _build(t, d, r, 'Լուծեք՝ $a(x − $b) = ${a * (x - b)}։ Գտեք x-ը։', x,
            'x − $b = ${x - b}, ուստի x = $x։');
    }
  }

  static Question _geometry(String t, int d, Random r) {
    switch (d) {
      case 1:
        final a = 3 + r.nextInt(15);
        final b = 2 + r.nextInt(12);
        return _build(t, d, r, 'Ուղղանկյան կողմերը $a և $b են։ Գտեք մակերեսը։', a * b, '$a · $b = ${a * b}։');
      case 2:
        final a = 3 + r.nextInt(15);
        final b = 2 + r.nextInt(12);
        return _build(t, d, r, 'Ուղղանկյան կողմերը $a և $b են։ Գտեք պարագիծը։', 2 * (a + b),
            '2 · ($a + $b) = ${2 * (a + b)}։');
      case 3:
        const triples = [
          [3, 4, 5],
          [5, 12, 13],
          [8, 15, 17],
          [7, 24, 25],
        ];
        final tr = triples[r.nextInt(triples.length)];
        final k = 1 + r.nextInt(3);
        return _build(t, d, r, 'Ուղղանկյուն եռանկյան էջերը ${tr[0] * k} և ${tr[1] * k} են։ Գտեք ներքնաձիգը։',
            tr[2] * k, 'Պյութագորաս՝ c = ${tr[2] * k}։');
      case 4:
        final rad = 2 + r.nextInt(9);
        return _build(t, d, r, 'Գտեք $rad շառավղով շրջանի մակերեսը (π ≈ 3,14)։', 3.14 * rad * rad,
            '3,14 · $rad² = ${(3.14 * rad * rad).toStringAsFixed(2)}։');
      default:
        const heron = [
          [13, 14, 15, 84],
          [5, 5, 6, 12],
          [6, 25, 29, 60],
          [9, 10, 17, 36],
          [7, 15, 20, 42],
        ];
        final h = heron[r.nextInt(heron.length)];
        return _build(t, d, r, 'Եռանկյան կողմերը ${h[0]}, ${h[1]} և ${h[2]} են։ Գտեք մակերեսը (Հերոնի բանաձև)։',
            h[3], 'p = ${(h[0] + h[1] + h[2]) / 2}, S = √(p(p−a)(p−b)(p−c)) = ${h[3]}։');
    }
  }

  static Question _logic(String t, int d, Random r) {
    switch (d) {
      case 1:
        final s = 1 + r.nextInt(15);
        final step = 2 + r.nextInt(8);
        final items = [for (var i = 0; i < 4; i++) s + i * step];
        return _build(t, d, r, _seq(items), s + 4 * step, 'Տարբերությունը $step է։');
      case 2:
        final s = 40 + r.nextInt(60);
        final step = 3 + r.nextInt(7);
        final items = [for (var i = 0; i < 4; i++) s - i * step];
        return _build(t, d, r, _seq(items), s - 4 * step, 'Յուրաքանչյուր անգամ նվազում է $step-ով։');
      case 3:
        final s = 1 + r.nextInt(4);
        final q = 2 + r.nextInt(3);
        final items = [for (var i = 0; i < 4; i++) s * pow(q, i).toInt()];
        return _build(t, d, r, _seq(items), s * pow(q, 4).toInt(), 'Յուրաքանչյուր անգամ բազմապատկվում է $q-ով։');
      case 4:
        final a = 1 + r.nextInt(9);
        final items = [a, a + 1, a + 3, a + 6, a + 10];
        return _build(t, d, r, _seq(items), a + 15, 'Տարբերությունները աճում են՝ +1, +2, +3, +4, հաջորդը՝ +5։');
      default:
        final x1 = 1 + r.nextInt(4);
        final x2 = 2 + r.nextInt(4);
        final items = <int>[x1, x2];
        while (items.length < 5) {
          items.add(items[items.length - 1] + items[items.length - 2]);
        }
        return _build(t, d, r, _seq(items), items[3] + items[4],
            'Յուրաքանչյուր անդամ երկու նախորդների գումարն է (Ֆիբոնաչիի տիպ)։');
    }
  }
}

/// Հարցերի ամբողջական ֆոնդ տվյալ թեմայի համար՝ պատրաստի + գեներացված + AI։
class QuestionProvider {
  QuestionProvider({this.ai, Random? random}) : _random = random ?? Random();

  final QuestionSource? ai;
  final Random _random;

  Future<List<Question>> poolFor(
    Topic topic, {
    required int minDifficulty,
    required int maxDifficulty,
    String? weakness,
  }) async {
    final pool = <Question>[...QuestionBank.forTopic(topic.id)];
    if (topic.id.startsWith('math.')) {
      for (var d = 1; d <= 5; d++) {
        pool.addAll(MathGenerator.make(topic.id, d, 4, _random));
      }
    }
    final source = ai;
    final subject = subjectById(topic.subjectId);
    if (source != null && subject != null) {
      try {
        final generated = await source.generate(
          subject: subject,
          topic: topic,
          minDifficulty: max(1, minDifficulty - 1),
          maxDifficulty: min(5, maxDifficulty + 1),
          count: 10,
          weakness: weakness,
        );
        pool.addAll(generated);
      } catch (_) {
        // AI-ն անհասանելի է. շարունակում ենք պատրաստի հարցերով։
      }
    }
    return pool;
  }
}

/// AI-ով (Claude API) նոր հարցերի ստեղծում։
///
/// Միացնելու համար գործարկեք՝ flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
/// Եթե բանալին դատարկ է, հավելվածը օգտագործում է պատրաստի և գեներացվող հարցեր։
class AiQuestionSource implements QuestionSource {
  AiQuestionSource({
    this.apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY'),
    this.endpoint = 'https://api.anthropic.com/v1/messages',
    this.model = 'claude-sonnet-5-5',
  });

  final String apiKey;
  final String endpoint;
  final String model;

  bool get enabled => apiKey.isNotEmpty;

  @override
  Future<List<Question>> generate({
    required LearnSubject subject,
    required Topic topic,
    required int minDifficulty,
    required int maxDifficulty,
    required int count,
    String? weakness,
  }) async {
    if (!enabled) return const [];
    final prompt = _prompt(subject, topic, minDifficulty, maxDifficulty, count, weakness);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers
        ..set('content-type', 'application/json')
        ..set('x-api-key', apiKey)
        ..set('anthropic-version', '2023-06-01');
      request.add(utf8.encode(jsonEncode({
        'model': model,
        'max_tokens': 4000,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      })));
      final response = await request.close().timeout(const Duration(seconds: 45));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('AI status ${response.statusCode}');
      }
      final root = jsonDecode(body) as Map<String, dynamic>;
      final content = root['content'] as List<dynamic>? ?? const [];
      final text = content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'text')
          .map((part) => '${part['text']}')
          .join();
      return parse(text, subject: subject, topic: topic);
    } finally {
      client.close(force: true);
    }
  }

  /// Վերլուծում է AI-ի պատասխանը (JSON զանգված) և դեն նետում անվավեր հարցերը։
  static List<Question> parse(
    String text, {
    required LearnSubject subject,
    required Topic topic,
  }) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start < 0 || end <= start) return const [];
    final decoded = jsonDecode(text.substring(start, end + 1));
    if (decoded is! List) return const [];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final out = <Question>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map<String, dynamic>) continue;
      try {
        out.add(Question.fromJson(
          item,
          id: 'ai.${topic.id}.$stamp.$i',
          subjectId: subject.id,
          topicId: topic.id,
        ));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  String _prompt(
    LearnSubject subject,
    Topic topic,
    int minD,
    int maxD,
    int count,
    String? weakness,
  ) {
    final extra = weakness == null ? '' : '\nThe student struggles with: $weakness. Include a few simpler exercises on it.';
    final language = subject.codeLanguage == null ? '' : '\nProgramming/markup language: ${subject.codeLanguage}.';
    return '''
You create quiz questions for a learning app. Subject: "${subject.title}". Topic: "${topic.title}".$language
Write all texts (prompt, options, explanation) in Armenian, except code, formulas and foreign-language words that are the object of the exercise.
Create exactly $count questions with difficulty from $minD to $maxD (integer 1-5), mixing these types:
multipleChoice, trueFalse, fillBlank, matching, ordering, numeric, code, open.$extra

Return ONLY a JSON array, no markdown. Each element has these fields:
- "type": one of the types above
- "difficulty": 1-5
- "prompt": the question text (for code questions include the code inside the prompt using \\n)
- "explanation": short explanation of the correct answer
- multipleChoice: "options" (3-4 strings), "answerIndex" (0-based)
- trueFalse: "answerIndex" (0 means true, 1 means false)
- fillBlank and code: "accepted" (list of accepted short answers)
- numeric: "numericAnswer" (number)
- ordering: "options" (items in the CORRECT order, 3-5 items)
- matching: "options" (left items) and "rights" (right items; rights[i] matches options[i]), 3-4 pairs
- open: "keywords" (3-5 stems that a good answer should contain)
Every question must have exactly one unambiguous correct answer.
''';
  }
}
