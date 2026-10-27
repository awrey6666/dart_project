import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'calendar_page.dart';
import 'homework_page.dart';
import 'grades_page.dart';
import 'study_scope.dart';
import 'subjects_page.dart';

class StudyShell extends StatefulWidget {
  const StudyShell({super.key});

  @override
  State<StudyShell> createState() => _StudyShellState();
}

class _StudyShellState extends State<StudyShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = StudyScope.of(context);
    const pages = [
      DashboardPage(),
      SubjectsPage(),
      CalendarPage(),
      HomeworkPage(),
      GradesPage(),
    ];
    const titles = ['Գլխավոր', 'Առարկաներ', 'Օրացույց', 'Աշխատանք', 'Արդյունքներ'];
    final wide = MediaQuery.sizeOf(context).width >= 900;

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard),
        label: 'Գլխավոր',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Առարկա',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Օրացույց',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Անելիք',
      ),
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights),
        label: 'Միջին',
      ),
    ];

    return NavScope(
      goTo: (index) => setState(() => _index = index),
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_index]),
          actions: [
            PopupMenuButton<ThemeMode>(
              tooltip: 'Թեմա',
              icon: Icon(_themeIcon(controller.themeMode)),
              onSelected: controller.setThemeMode,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('Ինչպես հեռախոսում'),
                ),
                PopupMenuItem(value: ThemeMode.light, child: Text('Բաց թեմա')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Մուգ թեմա')),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (index) => setState(() => _index = index),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                ],
              ),
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (index) => setState(() => _index = index),
                destinations: destinations,
              ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }
}
