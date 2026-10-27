import 'package:flutter/material.dart';

import '../data/study_repository.dart';
import '../logic/academics.dart';
import '../models/study_data.dart';
import '../util/format.dart';

class StudyController extends ChangeNotifier {
  StudyController(this._repository);

  final StudyRepository _repository;

  var _subjects = <Subject>[];
  var _lessons = <Lesson>[];
  var _notes = <StudyNote>[];
  var _resources = <StudyResource>[];
  var _homework = <HomeworkItem>[];
  var _exams = <ExamItem>[];
  var _grades = <GradeItem>[];
  ThemeMode themeMode = ThemeMode.system;

  List<Subject> get subjects {
    final copy = [..._subjects];
    copy.sort((a, b) => a.name.compareTo(b.name));
    return copy;
  }

  List<Lesson> get lessons {
    final copy = [..._lessons];
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<StudyNote> get notes {
    final copy = [..._notes];
    copy.sort((a, b) => a.title.compareTo(b.title));
    return copy;
  }

  List<StudyResource> get resources {
    final copy = [..._resources];
    copy.sort((a, b) => a.title.compareTo(b.title));
    return copy;
  }

  List<HomeworkItem> get homework {
    final copy = [..._homework];
    copy.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final byDue = a.due.compareTo(b.due);
      if (byDue != 0) return byDue;
      return b.priority.index.compareTo(a.priority.index);
    });
    return copy;
  }

  List<ExamItem> get exams {
    final copy = [..._exams];
    copy.sort((a, b) => a.when.compareTo(b.when));
    return copy;
  }

  List<GradeItem> get grades {
    final copy = [..._grades];
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  Subject? subjectById(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  List<Lesson> lessonsFor(String subjectId) =>
      lessons.where((item) => item.subjectId == subjectId).toList();

  List<Lesson> lessonsOn(DateTime date) =>
      lessons.where((item) => sameDay(item.date, date)).toList();

  List<StudyNote> notesFor(String subjectId) =>
      notes.where((item) => item.subjectId == subjectId).toList();

  List<StudyResource> resourcesFor(String subjectId) =>
      resources.where((item) => item.subjectId == subjectId).toList();

  List<HomeworkItem> homeworkFor(String subjectId) =>
      homework.where((item) => item.subjectId == subjectId).toList();

  List<HomeworkItem> homeworkOn(DateTime date) =>
      homework.where((item) => sameDay(item.due, date)).toList();

  List<ExamItem> examsFor(String subjectId) =>
      exams.where((item) => item.subjectId == subjectId).toList();

  List<ExamItem> examsOn(DateTime date) =>
      exams.where((item) => sameDay(item.when, date)).toList();

  List<GradeItem> gradesFor(String subjectId) =>
      grades.where((item) => item.subjectId == subjectId).toList();

  List<HomeworkItem> get openHomework =>
      homework.where((item) => !item.done).toList();

  List<ExamItem> get upcomingExams =>
      exams.where((exam) => !exam.when.isBefore(DateTime.now())).toList();

  double? get overallAverage => Academics.overallAverage(_subjects, _grades);

  double? averageFor(String subjectId) {
    return Academics.weightedAverage(
      _grades.where((grade) => grade.subjectId == subjectId).toList(),
    );
  }

  Future<void> init() async {
    final stored = await _repository.load();
    _apply(stored ?? StudyData.sample());
    if (stored == null) {
      await _repository.save(_snapshot());
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<String?> saveSubject(Subject subject) async {
    final name = subject.name.trim();
    if (name.isEmpty) return 'Գրեք առարկայի անունը։';
    final next = subject.copyWith(name: name);
    final index = _subjects.indexWhere((item) => item.id == subject.id);
    if (index >= 0) {
      _subjects[index] = next;
    } else {
      _subjects.add(next);
    }
    notifyListeners();
    return _persist();
  }

  Future<String?> deleteSubject(String id) async {
    _subjects.removeWhere((item) => item.id == id);
    _lessons.removeWhere((item) => item.subjectId == id);
    _notes.removeWhere((item) => item.subjectId == id);
    _resources.removeWhere((item) => item.subjectId == id);
    _homework.removeWhere((item) => item.subjectId == id);
    _exams.removeWhere((item) => item.subjectId == id);
    _grades.removeWhere((item) => item.subjectId == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveLesson(Lesson lesson) async {
    if (lesson.title.trim().isEmpty) return 'Գրեք դասի թեման։';
    if (subjectById(lesson.subjectId) == null) return 'Ընտրեք առարկա։';
    return _upsert(_lessons, lesson, (item) => item.id);
  }

  Future<String?> deleteLesson(String id) async {
    _lessons.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveNote(StudyNote note) async {
    if (note.title.trim().isEmpty) return 'Գրեք նշման վերնագիրը։';
    if (subjectById(note.subjectId) == null) return 'Ընտրեք առարկա։';
    return _upsert(_notes, note, (item) => item.id);
  }

  Future<String?> deleteNote(String id) async {
    _notes.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveResource(StudyResource resource) async {
    if (resource.title.trim().isEmpty) return 'Գրեք աղբյուրի անունը։';
    if (resource.detail.trim().isEmpty) return 'Գրեք հղում կամ կարճ բացատրություն։';
    if (subjectById(resource.subjectId) == null) return 'Ընտրեք առարկա։';
    return _upsert(_resources, resource, (item) => item.id);
  }

  Future<String?> deleteResource(String id) async {
    _resources.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveHomework(HomeworkItem item) async {
    if (item.title.trim().isEmpty) return 'Գրեք վերնագիր։';
    if (subjectById(item.subjectId) == null) return 'Ընտրեք առարկա։';
    final index = _homework.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _homework[index] = item;
    } else {
      _homework.add(item);
    }
    notifyListeners();
    return _persist();
  }

  Future<String?> setHomeworkStatus(String id, TaskStatus status) async {
    final index = _homework.indexWhere((item) => item.id == id);
    if (index < 0) return 'Այս աշխատանքն արդեն չկա։';
    _homework[index] = _homework[index].copyWith(status: status);
    notifyListeners();
    return _persist();
  }

  Future<String?> deleteHomework(String id) async {
    _homework.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveExam(ExamItem item) async {
    if (item.title.trim().isEmpty) return 'Գրեք վերնագիր։';
    if (subjectById(item.subjectId) == null) return 'Ընտրեք առարկա։';
    final index = _exams.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _exams[index] = item;
    } else {
      _exams.add(item);
    }
    notifyListeners();
    return _persist();
  }

  Future<String?> deleteExam(String id) async {
    _exams.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  Future<String?> saveGrade(GradeItem item) async {
    if (item.title.trim().isEmpty) return 'Գրեք վերնագիր։';
    if (subjectById(item.subjectId) == null) return 'Ընտրեք առարկա։';
    if (item.maxScore <= 0) return 'Առավելագույն միավորը պետք է մեծ լինի զրոյից։';
    if (item.score < 0 || item.score > item.maxScore) {
      return 'Ստացած միավորը պետք է լինի 0-ից մինչև առավելագույնը։';
    }
    if (item.weight <= 0) return 'Կարևորությունը պետք է մեծ լինի զրոյից։';
    final index = _grades.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _grades[index] = item;
    } else {
      _grades.add(item);
    }
    notifyListeners();
    return _persist();
  }

  Future<String?> deleteGrade(String id) async {
    _grades.removeWhere((item) => item.id == id);
    notifyListeners();
    return _persist();
  }

  void _apply(StudyData data) {
    _subjects = [...data.subjects];
    _lessons = [...data.lessons];
    _notes = [...data.notes];
    _resources = [...data.resources];
    _homework = [...data.homework];
    _exams = [...data.exams];
    _grades = [...data.grades];
    themeMode = data.themeMode;
  }

  StudyData _snapshot() {
    return StudyData(
      subjects: _subjects,
      lessons: _lessons,
      notes: _notes,
      resources: _resources,
      homework: _homework,
      exams: _exams,
      grades: _grades,
      themeMode: themeMode,
    );
  }

  Future<String?> _upsert<T>(List<T> items, T item, String Function(T item) idOf) async {
    final index = items.indexWhere((entry) => idOf(entry) == idOf(item));
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    notifyListeners();
    return _persist();
  }

  Future<String?> _persist() async {
    try {
      await _repository.save(_snapshot());
      return null;
    } catch (_) {
      return 'Չհաջողվեց պահել փոփոխությունը այս սարքում։';
    }
  }
}
