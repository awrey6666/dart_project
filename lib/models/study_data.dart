import 'package:flutter/material.dart';

const subjectPalette = <int>[
  0xFF1F6F8B,
  0xFF2E7D32,
  0xFF6A1B9A,
  0xFFEF6C00,
  0xFFC62828,
  0xFF1565C0,
  0xFF5D4037,
  0xFF00838F,
];

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.teacher,
    required this.room,
    required this.colorValue,
    required this.credits,
  });

  final String id;
  final String name;
  final String teacher;
  final String room;
  final int colorValue;
  final double credits;

  Color get color => Color(colorValue);

  Subject copyWith({
    String? name,
    String? teacher,
    String? room,
    int? colorValue,
    double? credits,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      colorValue: colorValue ?? this.colorValue,
      credits: credits ?? this.credits,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'room': room,
    'colorValue': colorValue,
    'credits': credits,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    teacher: json['teacher'] as String? ?? '',
    room: json['room'] as String? ?? '',
    colorValue: json['colorValue'] as int,
    credits: (json['credits'] as num?)?.toDouble() ?? 1,
  );
}

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, doing, done }

String priorityLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => 'Ցածր',
    TaskPriority.medium => 'Միջին',
    TaskPriority.high => 'Բարձր',
  };
}

String statusLabel(TaskStatus status) {
  return switch (status) {
    TaskStatus.todo => 'Անելիք',
    TaskStatus.doing => 'Ընթացքում',
    TaskStatus.done => 'Արված',
  };
}

class Lesson {
  const Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.date,
    required this.summary,
  });

  final String id;
  final String subjectId;
  final String title;
  final DateTime date;
  final String summary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'date': date.toIso8601String(),
    'summary': summary,
  };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    summary: json['summary'] as String? ?? '',
  );
}

class StudyNote {
  const StudyNote({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.body,
  });

  final String id;
  final String subjectId;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'body': body,
  };

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
  );
}

class StudyResource {
  const StudyResource({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.detail,
  });

  final String id;
  final String subjectId;
  final String title;
  final String detail;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'detail': detail,
  };

  factory StudyResource.fromJson(Map<String, dynamic> json) => StudyResource(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    detail: json['detail'] as String? ?? '',
  );
}

class HomeworkItem {
  const HomeworkItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.notes,
    required this.due,
    required this.priority,
    required this.status,
  });

  final String id;
  final String subjectId;
  final String title;
  final String notes;
  final DateTime due;
  final TaskPriority priority;
  final TaskStatus status;

  bool get done => status == TaskStatus.done;

  HomeworkItem copyWith({TaskStatus? status, TaskPriority? priority}) {
    return HomeworkItem(
      id: id,
      subjectId: subjectId,
      title: title,
      notes: notes,
      due: due,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'notes': notes,
    'due': due.toIso8601String(),
    'priority': priority.name,
    'status': status.name,
  };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = statusName == null
        ? ((json['done'] as bool? ?? false) ? TaskStatus.done : TaskStatus.todo)
        : TaskStatus.values.firstWhere(
            (value) => value.name == statusName,
            orElse: () => TaskStatus.todo,
          );
    return HomeworkItem(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      due: DateTime.parse(json['due'] as String),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: status,
    );
  }
}

class ExamItem {
  const ExamItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.when,
    required this.location,
    required this.notes,
  });

  final String id;
  final String subjectId;
  final String title;
  final DateTime when;
  final String location;
  final String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'when': when.toIso8601String(),
    'location': location,
    'notes': notes,
  };

  factory ExamItem.fromJson(Map<String, dynamic> json) => ExamItem(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    when: DateTime.parse(json['when'] as String),
    location: json['location'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}

class GradeItem {
  const GradeItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.weight,
    required this.date,
  });

  final String id;
  final String subjectId;
  final String title;
  final double score;
  final double maxScore;
  final double weight;
  final DateTime date;

  double get percent => maxScore == 0 ? 0 : score / maxScore * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'score': score,
    'maxScore': maxScore,
    'weight': weight,
    'date': date.toIso8601String(),
  };

  factory GradeItem.fromJson(Map<String, dynamic> json) => GradeItem(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    title: json['title'] as String,
    score: (json['score'] as num).toDouble(),
    maxScore: (json['maxScore'] as num).toDouble(),
    weight: (json['weight'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );
}

class StudyData {
  const StudyData({
    required this.subjects,
    required this.lessons,
    required this.notes,
    required this.resources,
    required this.homework,
    required this.exams,
    required this.grades,
    required this.themeMode,
  });

  final List<Subject> subjects;
  final List<Lesson> lessons;
  final List<StudyNote> notes;
  final List<StudyResource> resources;
  final List<HomeworkItem> homework;
  final List<ExamItem> exams;
  final List<GradeItem> grades;
  final ThemeMode themeMode;

  Map<String, dynamic> toJson() => {
    'subjects': subjects.map((item) => item.toJson()).toList(),
    'lessons': lessons.map((item) => item.toJson()).toList(),
    'notes': notes.map((item) => item.toJson()).toList(),
    'resources': resources.map((item) => item.toJson()).toList(),
    'homework': homework.map((item) => item.toJson()).toList(),
    'exams': exams.map((item) => item.toJson()).toList(),
    'grades': grades.map((item) => item.toJson()).toList(),
    'themeMode': themeMode.name,
  };

  factory StudyData.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      String key,
      T Function(Map<String, dynamic> json) decode,
    ) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((item) => decode(item as Map<String, dynamic>)).toList();
    }

    return StudyData(
      subjects: readList('subjects', Subject.fromJson),
      lessons: readList('lessons', Lesson.fromJson),
      notes: readList('notes', StudyNote.fromJson),
      resources: readList('resources', StudyResource.fromJson),
      homework: readList('homework', HomeworkItem.fromJson),
      exams: readList('exams', ExamItem.fromJson),
      grades: readList('grades', GradeItem.fromJson),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
    );
  }

  factory StudyData.sample() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return StudyData(
      themeMode: ThemeMode.system,
      subjects: const [
        Subject(
          id: 'sub-math',
          name: 'Գծային հանրահաշիվ',
          teacher: 'Ա. Հովհաննիսյան',
          room: 'լսարան Բ204',
          colorValue: 0xFF1F6F8B,
          credits: 4,
        ),
        Subject(
          id: 'sub-physics',
          name: 'Ֆիզիկա',
          teacher: 'Մ. Պետրոսյան',
          room: 'լաբորատորիա 2',
          colorValue: 0xFF2E7D32,
          credits: 4,
        ),
        Subject(
          id: 'sub-writing',
          name: 'Ակադեմիական գրավոր',
          teacher: 'Ն. Սարգսյան',
          room: 'լսարան Ա118',
          colorValue: 0xFF6A1B9A,
          credits: 3,
        ),
        Subject(
          id: 'sub-history',
          name: 'Համաշխարհային պատմություն',
          teacher: 'Կ. Գրիգորյան',
          room: 'լսարան Գ301',
          colorValue: 0xFFEF6C00,
          credits: 3,
        ),
      ],
      lessons: [
        Lesson(
          id: 'les-math',
          subjectId: 'sub-math',
          title: 'Վեկտորական տարածություն',
          date: day,
          summary: 'Տարածություն, բազիս և չափողականություն։ Լսարան Բ204, դասախոս Ա. Հովհաննիսյան։',
        ),
        Lesson(
          id: 'les-physics',
          subjectId: 'sub-physics',
          title: 'Ուժ և շարժում',
          date: day.add(const Duration(days: 1)),
          summary: 'Լաբորատորիա 2, դասախոս Մ. Պետրոսյան։',
        ),
      ],
      notes: const [
        StudyNote(
          id: 'note-math',
          subjectId: 'sub-math',
          title: 'Բազիսի հիշեցում',
          body: 'Բազիսը գծային անկախ է և ծածկում է ամբողջ տարածությունը։',
        ),
      ],
      resources: const [
        StudyResource(
          id: 'res-math',
          subjectId: 'sub-math',
          title: 'Դասագրքի 3-րդ գլուխ',
          detail: '3.1–3.4 բաժիններ, 1–6 վարժություններ։',
        ),
      ],
      homework: [
        HomeworkItem(
          id: 'hw-overdue',
          subjectId: 'sub-physics',
          title: 'Լաբորատոր աշխատանքի սևագիր',
          notes: 'Ավելացրեք սխալի աղյուսակը։',
          due: day.subtract(const Duration(days: 1)),
          priority: TaskPriority.high,
          status: TaskStatus.todo,
        ),
        HomeworkItem(
          id: 'hw-today',
          subjectId: 'sub-math',
          title: 'Խնդիրների փաթեթ 4',
          notes: '3-րդ գլխի 1–6 խնդիրները։',
          due: day,
          priority: TaskPriority.medium,
          status: TaskStatus.doing,
        ),
        HomeworkItem(
          id: 'hw-soon',
          subjectId: 'sub-writing',
          title: 'Շարադրության պլան',
          notes: 'Բերեք հիմնական միտքը և երեք աղբյուր։',
          due: day.add(const Duration(days: 2)),
          priority: TaskPriority.low,
          status: TaskStatus.todo,
        ),
        HomeworkItem(
          id: 'hw-done',
          subjectId: 'sub-history',
          title: 'Ընթերցանության նշումներ',
          notes: '',
          due: day.subtract(const Duration(days: 4)),
          priority: TaskPriority.medium,
          status: TaskStatus.done,
        ),
      ],
      exams: [
        ExamItem(
          id: 'ex-math',
          subjectId: 'sub-math',
          title: 'Միջանկյալ քննություն',
          when: day.add(const Duration(days: 4, hours: 9)),
          location: 'դահլիճ Ա',
          notes: '1–4 գլուխներ։ Հաշվիչը թույլատրվում է։',
        ),
        ExamItem(
          id: 'ex-history',
          subjectId: 'sub-history',
          title: 'Աղբյուրների ստուգողական',
          when: day.add(const Duration(days: 11, hours: 14)),
          location: 'C301',
          notes: '',
        ),
      ],
      grades: [
        GradeItem(
          id: 'gr-math-1',
          subjectId: 'sub-math',
          title: 'Ստուգողական 1',
          score: 18,
          maxScore: 20,
          weight: 1,
          date: day.subtract(const Duration(days: 12)),
        ),
        GradeItem(
          id: 'gr-math-2',
          subjectId: 'sub-math',
          title: 'Խնդիրների փաթեթ 3',
          score: 42,
          maxScore: 50,
          weight: 2,
          date: day.subtract(const Duration(days: 6)),
        ),
        GradeItem(
          id: 'gr-phy',
          subjectId: 'sub-physics',
          title: 'Լաբորատոր 2',
          score: 9,
          maxScore: 10,
          weight: 1,
          date: day.subtract(const Duration(days: 8)),
        ),
        GradeItem(
          id: 'gr-wri',
          subjectId: 'sub-writing',
          title: 'Կարճ շարադրություն',
          score: 86,
          maxScore: 100,
          weight: 2,
          date: day.subtract(const Duration(days: 10)),
        ),
        GradeItem(
          id: 'gr-his',
          subjectId: 'sub-history',
          title: 'Աղբյուրի վերլուծություն',
          score: 16,
          maxScore: 20,
          weight: 1,
          date: day.subtract(const Duration(days: 5)),
        ),
      ],
    );
  }
}

String createId() => DateTime.now().microsecondsSinceEpoch.toString();
