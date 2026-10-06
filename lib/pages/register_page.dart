import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //User Name / Comapny Name Controller
  final _nameController = TextEditingController();

  //Siugn Up Function
  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      await _authService.signUp(email, password, name);
      if(mounted){
        Navigator.pop(context); // Navigate back to the previous screen after successful sign-up
      }
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
        title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf7f8f9),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join FleetMetric today',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7f7f81),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: InputDecoration(
                  labelText: 'Name / Company Name',
                  labelStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  hintText: 'Enter your name or company name',
                  hintStyle: const TextStyle(color: Color(0xFF7f7f81)),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFfca541)),
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
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfca541),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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