import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/providers/auth_provider.dart';
import 'package:slack_chat_app/screens/home_screen.dart';
import 'package:slack_chat_app/screens/signup_screen.dart';
import 'package:slack_chat_app/widgets/auth_shell.dart';
import 'package:slack_chat_app/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _autoValidate = false;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Slack-like collaboration workspace',
      title: 'Welcome back',
      subtitle:
          'Pick up your conversations, channels, and direct messages right where you left them.',
      form: Form(
        key: _formKey,
        autovalidateMode:
            _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CustomTextField(
              controller: _identifierController,
              label: 'Email or username',
              hintText: 'ava@teamspace.dev or Ava Patel',
              prefixIcon: Icons.alternate_email_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateIdentifier,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_submissionError != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                _submissionError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(_isSubmitting ? 'Signing in...' : 'Sign in'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE4E0E8),
                ),
              ),
              child: Text(
                'Demo accounts: ava@teamspace.dev, sarah@teamspace.dev, marcus@teamspace.dev\nPassword for all: secret123',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF616061),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Need an account?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF616061),
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text('Create one'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter your email or username.';
    }

    if (input.contains('@')) {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(input)) {
        return 'Enter a valid email address.';
      }
    } else if (input.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _autoValidate = true;
      _submissionError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final error = await context.read<AuthProvider>().login(
          identifier: _identifierController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submissionError = error;
    });

    if (error != null) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
