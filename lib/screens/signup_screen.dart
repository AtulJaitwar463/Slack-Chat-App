import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/providers/auth_provider.dart';
import 'package:slack_chat_app/screens/home_screen.dart';
import 'package:slack_chat_app/widgets/auth_shell.dart';
import 'package:slack_chat_app/widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _autoValidate = false;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Create your local workspace account',
      title: 'Set up your profile',
      subtitle:
          'Sign up locally to explore channels, direct messages, search, and unread states with production-style UI.',
      form: Form(
        key: _formKey,
        autovalidateMode:
            _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CustomTextField(
              controller: _usernameController,
              label: 'Username',
              hintText: 'Your display name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateUsername,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'At least 6 characters',
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
                  child: Text(_isSubmitting ? 'Creating account...' : 'Create account'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) {
      return 'Enter a username.';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Create a password.';
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

    final error = await context.read<AuthProvider>().signup(
          username: _usernameController.text,
          email: _emailController.text,
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
