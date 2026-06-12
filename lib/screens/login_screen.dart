import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../app/theme_provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AuthService();
    final user = await auth.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (user == null) {
      setState(() {
        _error = 'Invalid credentials or network error.';
        _loading = false;
      });
    } else {
      if (mounted) context.go('/');
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AuthService();
    final user = await auth.signInAnonymously();
    if (user == null) {
      setState(() {
        _error = 'Could not continue as guest.';
        _loading = false;
      });
    } else {
      if (mounted) context.go('/');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? colorScheme.surface
                    : colorScheme.primaryContainer.withValues(alpha: 0.9),
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Main scrollable content takes all available space
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? colorScheme.surface
                                    : colorScheme.surface.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                                ),
                                boxShadow: Theme.of(context).brightness == Brightness.dark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 28,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                      size: 40,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Welcome back to KucITS',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to keep up with your favorite cats, posts, and cozy moments.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 24),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: Icon(Icons.alternate_email),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Enter email';
                                            }
                                            if (!v.contains('@')) {
                                              return 'Enter valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _passwordController,
                                          decoration: const InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: Icon(Icons.lock_outline),
                                          ),
                                          obscureText: true,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Enter password';
                                            }
                                            if (v.length < 6) {
                                              return 'Password too short';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        if (_error != null)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              _error!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.icon(
                                            onPressed: _loading ? null : _signIn,
                                            icon: _loading
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : null,
                                            label: Text(
                                              _loading ? 'Signing in...' : 'Sign in',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const RegisterScreen(),
                                                  ),
                                                );
                                              },
                                              child: const Text('Create account'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const ResetPasswordScreen(),
                                                  ),
                                                );
                                              },
                                              child: const Text('Forgot password?'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: _loading ? null : _signInAnonymously,
                                            icon: const Icon(Icons.person_outline),
                                            label: const Text('Continue as Guest'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Theme toggle — bottom center, always visible
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextButton.icon(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 18,
                      ),
                      label: Text(
                        themeProvider.isDarkMode ? 'Light mode' : 'Dark mode',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
