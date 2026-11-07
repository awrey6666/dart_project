import 'dart:convert';
import 'dart:io';

import 'learn_models.dart';

/// Պահում է օգտատերերին և յուրաքանչյուրի առաջընթացը առանձին ֆայլում։
class LearnRepository {
  LearnRepository({Directory? directory}) : _directory = directory;

  static const accountsFile = 'learn.accounts.json';
  static const contentFile = 'learn.content.json';

  final Directory? _directory;

  Directory get _dir {
    final directory = _directory ?? _defaultDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  Directory _defaultDirectory() {
    final base = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    return Directory('$base${Platform.pathSeparator}Usoum');
  }

  File _file(String name) => File('${_dir.path}${Platform.pathSeparator}$name');

  Future<({List<LearnAccount> accounts, String? currentId, bool adminOnly})> loadAccounts() async {
    try {
      final file = _file(accountsFile);
      if (!file.existsSync()) {
        return (accounts: <LearnAccount>[], currentId: null, adminOnly: false);
      }
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final accounts = (raw['users'] as List<dynamic>? ?? const [])
          .map((e) => LearnAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        accounts: accounts,
        currentId: raw['currentId'] as String?,
        // Եթե կարգավորումը դեռ պահված չէ, սովորողները կարող են մուտք գործել։
        adminOnly: raw['adminOnly'] == true,
      );
    } catch (_) {
      return (accounts: <LearnAccount>[], currentId: null, adminOnly: false);
    }
  }

  Future<void> saveAccounts(
    List<LearnAccount> accounts,
    String? currentId, {
    bool adminOnly = false,
  }) async {
    try {
      await _file(accountsFile).writeAsString(jsonEncode({
        'users': accounts.map((a) => a.toJson()).toList(),
        'currentId': currentId,
        'adminOnly': adminOnly,
      }));
    } catch (_) {
      throw StateError('Չհաջողվեց պահել հաշիվները։');
    }
  }

  /// Ադմինի խմբագրած նյութերը (առարկաներ, թեմաներ, հարցեր)։ `null`՝ եթե դեռ չկա։
  Future<Map<String, dynamic>?> loadContent() async {
    try {
      final file = _file(contentFile);
      if (!file.existsSync()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveContent(Map<String, dynamic> content) async {
    try {
      // Նախ գրում ենք ժամանակավոր ֆայլում, որպեսզի ընդհատման դեպքում հին տարբերակը չկորչի։
      final target = _file(contentFile);
      final temp = _file('$contentFile.tmp');
      await temp.writeAsString(jsonEncode(content));
      await temp.rename(target.path);
    } catch (_) {
      throw StateError('Չհաջողվեց պահել ուսումնական նյութերը։');
    }
  }

  Future<void> deleteContent() async {
    try {
      final file = _file(contentFile);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      throw StateError('Չհաջողվեց վերականգնել նյութերը։');
    }
  }

  Future<LearnProfile> loadProfile(String userId) async {
    try {
      final file = _file('learn.profile.$userId.json');
      if (!file.existsSync()) return LearnProfile(userId: userId);
      return LearnProfile.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return LearnProfile(userId: userId);
    }
  }

  Future<void> saveProfile(LearnProfile profile) async {
    try {
      await _file('learn.profile.${profile.userId}.json')
          .writeAsString(jsonEncode(profile.toJson()));
    } catch (_) {
      throw StateError('Չհաջողվեց պահել առաջընթացը։');
    }
  }
}
