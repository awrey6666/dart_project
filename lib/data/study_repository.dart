import 'dart:convert';
import 'dart:io';

import '../models/study_data.dart';

class StudyRepository {
<<<<<<< HEAD
  StudyRepository({this._directory});
=======
  StudyRepository({Directory? directory}) : _directory = directory;
>>>>>>> 66dfac4e8e78111e90f9bc9af8cc39e00edfc4f3

  static const fileName = 'studymate.v3.json';

  final Directory? _directory;

  Future<File> get _file async {
    final directory = _directory ?? _defaultDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Directory _defaultDirectory() {
    final base = Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    return Directory('$base${Platform.pathSeparator}Usoum');
  }

  Future<StudyData?> load() async {
    try {
      final file = await _file;
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return StudyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(StudyData data) async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (_) {
      throw StateError('Չհաջողվեց պահել տվյալները այս սարքում։');
    }
  }
}
