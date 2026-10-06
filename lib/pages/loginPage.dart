import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await _authService.signIn(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF100f14),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFfca541).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 60,
                  color: Color(0xFFfca541),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'FleetMetric',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf7f8f9),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your fleet efficiently',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7f7f81),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFfca541)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFfca541)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFfca541)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFfca541)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfca541),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    color: Color(0xFFfca541),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}