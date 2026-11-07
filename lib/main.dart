import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/study_repository.dart';
import 'learn/auth_page.dart';
import 'learn/learn_controller.dart';
import 'learn/learn_repository.dart';
import 'learn/learn_scope.dart';
import 'learn/question_source.dart';
import 'screens/study_scope.dart';
import 'state/study_controller.dart';
import 'theme/study_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = StudyController(StudyRepository());
  await controller.init();
  final learn = LearnController(
    LearnRepository(),
    provider: QuestionProvider(ai: AiQuestionSource()),
  );
  await learn.init();
  runApp(StudyMateApp(controller: controller, learn: learn));
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key, required this.controller, required this.learn});

  final StudyController controller;
  final LearnController learn;

  @override
  Widget build(BuildContext context) {
    return LearnScope(
      controller: learn,
      child: StudyScope(
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
            home: const AuthGate(),
          );
        },
      ),
      ),
    );
  }
}
