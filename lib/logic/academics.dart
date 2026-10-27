import '../models/study_data.dart';

class Academics {
  const Academics._();

  static double? weightedAverage(List<GradeItem> grades) {
    final weight = grades.fold<double>(0, (sum, grade) => sum + grade.weight);
    if (weight <= 0) return null;
    final total = grades.fold<double>(
      0,
      (sum, grade) => sum + grade.percent * grade.weight,
    );
    return total / weight;
  }

  static double? overallAverage(
    List<Subject> subjects,
    List<GradeItem> grades,
  ) {
    var creditSum = 0.0;
    var total = 0.0;
    for (final subject in subjects) {
      final average = weightedAverage(
        grades.where((grade) => grade.subjectId == subject.id).toList(),
      );
      if (average == null) continue;
      final credit = subject.credits <= 0 ? 1.0 : subject.credits;
      creditSum += credit;
      total += average * credit;
    }
    if (creditSum == 0) return null;
    return total / creditSum;
  }

  static double? homeworkCompletion(List<HomeworkItem> items) {
    if (items.isEmpty) return null;
    return items.where((item) => item.done).length / items.length;
  }

  static String letter(double percent) {
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }
}
