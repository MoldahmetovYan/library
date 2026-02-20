import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  bool _loading = false;
  bool _obscure = true;
  bool _didAddListener = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final notifier = ref.read(userProvider.notifier);
    final ok = await notifier.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go('/books');
    } else {
      final message = ref.read(userProvider).error ?? 'Login failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_didAddListener) {
      _didAddListener = true;
      ref.listen<UserState>(userProvider, (previous, next) {
        if (!mounted) return;
        final error = next.error;
        if (error != null && error != previous?.error && !_loading) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter email';
                  }
                  final emailRegex =
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter password';
                  }
                  if (value.length < 6) {
                    return 'Password too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: _loading ? null : () => context.go('/register'),
                child: const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
