import 'package:effora/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final userId = user.id;

        final prefsResponse = await supabase
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        final pendingUsername = prefs.getString('pending_username');

        if (prefsResponse == null) {
          // No entry exists at all
          await supabase.from('user_preferences').insert({
            'user_id': userId,
            'username': pendingUsername ?? '',
            'created_at': DateTime.now().toIso8601String(),
          });

          if (pendingUsername != null && pendingUsername.isNotEmpty) {
            await prefs.remove('pending_username');
          }
        } else {
          final existingUsername = prefsResponse['username'] ?? '';

          if ((existingUsername as String).trim().isEmpty &&
              pendingUsername != null &&
              pendingUsername.trim().isNotEmpty) {
            await supabase
                .from('user_preferences')
                .update({'username': pendingUsername})
                .eq('user_id', userId);

            await prefs.remove('pending_username');
          }

          if ((existingUsername).trim().isEmpty &&
              (pendingUsername == null || pendingUsername.isEmpty)) {
            await _promptForUsername(userId);
          }
        }

        final alreadySynced = prefs.getBool('supabase_synced') ?? false;
        if (!alreadySynced) {
          await SupabaseService().syncAllExistingHiveData();
          await prefs.setBool('supabase_synced', true);
        }

        await SupabaseService().syncFromSupabaseToHive();

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError("Login failed: No session returned.");
      }
    } catch (e) {
      _showError("Login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _promptForUsername(String userId) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Complete Your Profile"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Enter your username",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Skip"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isNotEmpty) {
                await supabase
                    .from('user_preferences')
                    .update({'username': newUsername})
                    .eq('user_id', userId);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, size: 72, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                "Effora",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Empower your hustle, own your success.",
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              _showError("Please enter your email to reset password.");
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/reset-password',
                                arguments: email,
                              );
                            }
                          },
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signIn,
                          icon: const Icon(Icons.login),
                          label: const Text("Login"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text("New user? Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
