import 'package:dart_project/logic/academics.dart';
import 'package:dart_project/models/study_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 1, 1);

  test('weighted grades and letters follow the published scale', () {
    final grades = [
      GradeItem(
        id: 'a',
        subjectId: 'math',
        title: 'Quiz',
        score: 18,
        maxScore: 20,
        weight: 1,
        date: date,
      ),
      GradeItem(
        id: 'b',
        subjectId: 'math',
        title: 'Exam',
        score: 40,
        maxScore: 50,
        weight: 2,
        date: date,
      ),
    ];
    final average = Academics.weightedAverage(grades);
    expect(average, closeTo((90 + 80 + 80) / 3, 0.001));
    expect(Academics.letter(average!), 'B');
    expect(Academics.letter(90), 'A');
    expect(Academics.letter(59), 'F');
  });

  test('overall average uses subject credits', () {
    const subjects = [
      Subject(
        id: 'math',
        name: 'Math',
        teacher: '',
        room: '',
        colorValue: 1,
        credits: 4,
      ),
      Subject(
        id: 'art',
        name: 'Art',
        teacher: '',
        room: '',
        colorValue: 1,
        credits: 2,
      ),
    ];
    final grades = [
      GradeItem(
        id: 'm',
        subjectId: 'math',
        title: 'Test',
        score: 80,
        maxScore: 100,
        weight: 1,
        date: date,
      ),
      GradeItem(
        id: 'a',
        subjectId: 'art',
        title: 'Test',
        score: 100,
        maxScore: 100,
        weight: 1,
        date: date,
      ),
    ];
    expect(
      Academics.overallAverage(subjects, grades),
      closeTo((80 * 4 + 100 * 2) / 6, 0.001),
    );
  });

  test('stored data round-trips through json', () {
    final data = StudyData.sample();
    final restored = StudyData.fromJson(data.toJson());
    expect(restored.subjects.length, data.subjects.length);
    expect(restored.lessons.first.title, data.lessons.first.title);
    expect(restored.homework.first.done, data.homework.first.done);
    expect(restored.exams.first.when, data.exams.first.when);
    expect(restored.grades.first.score, data.grades.first.score);
  });
}
