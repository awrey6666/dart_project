import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/study_repository.dart';
import 'screens/study_scope.dart';
import 'screens/study_shell.dart';
import 'state/study_controller.dart';
import 'theme/study_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = StudyController(StudyRepository());
  await controller.init();
  runApp(StudyMateApp(controller: controller));
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key, required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    return StudyScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Ուսում',
            debugShowCheckedModeBanner: false,
            locale: const Locale('hy'),
            supportedLocales: const [Locale('hy')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: StudyTheme.light(),
            darkTheme: StudyTheme.dark(),
            themeMode: controller.themeMode,
            home: const StudyShell(),
          );
        },
      ),
    );
  }
}
