import 'package:flutter/material.dart';

import '../screens/study_shell.dart';
import 'admin_page.dart';
import 'learn_scope.dart';

/// Եթե օգտատերը մուտք չի գործել՝ ցույց է տալիս մուտքի էջը։ Ադմինի տվյալներով
/// մուտքի դեպքում բացվում է ադմինի վահանակը, մնացածի համար՝ հիմնական հավելվածը։
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final learn = LearnScope.of(context);
    if (learn.isAdmin) return const AdminPage(showLogout: true);
    return learn.signedIn ? const StudyShell() : const AuthPage();
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool? _registerMode;
  var _busy = false;
  var _hidden = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final learn = LearnScope.of(context);
    final register = learn.registrationOpen && (_registerMode ?? false);
    final error = register
        ? await learn.register(_name.text, _password.text)
        : await learn.login(_name.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final learn = LearnScope.of(context);
    // Սկզբնական էկրանը միշտ մուտքն է (ադմինը այստեղից է մտնում վահանակ)։
    final register = learn.registrationOpen && (_registerMode ?? false);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.school, size: 48, color: scheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        'StudyMate',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ուսուցում և գիտելիքների զարգացում՝ խաղի միջոցով',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Անուն',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: _hidden,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Գաղտնաբառ',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidden ? 'Ցույց տալ' : 'Թաքցնել',
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _hidden = !_hidden),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(register ? 'Ստեղծել հաշիվ' : 'Մուտք'),
                      ),
                      const SizedBox(height: 8),
                      if (learn.registrationOpen)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _registerMode = !register;
                                  _error = null;
                                }),
                          child: Text(
                            register
                                ? 'Արդեն ունե՞ք հաշիվ։ Մուտք'
                                : 'Նոր օգտատեր։ Ստեղծել հաշիվ',
                          ),
                        ),
                      if (learn.adminOnlyLogin)
                        Text(
                          'Մուտքը թույլատրված է միայն ադմիններին։',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
