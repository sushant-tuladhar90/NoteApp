import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:note_app_ui/services/auth_service.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();

  final _auth = AuthService();
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // Password should be at least 8 characters long and contain at least one number
    return password.length >= 8 && RegExp(r'[0-9]').hasMatch(password);
  }

  String? _validateFields() {
    if (_usernameController.text.isEmpty) {
      return 'Username is required';
    }
    
    if (_emailController.text.isEmpty) {
      return 'Email is required';
    }
    
    if (!_isValidEmail(_emailController.text)) {
      return 'Please enter a valid email address';
    }
    
    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    
    if (!_isValidPassword(_passwordController.text)) {
      return 'Password must be at least 8 characters long and contain at least one number';
    }
    
    if (_confirmpasswordController.text.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (_passwordController.text != _confirmpasswordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  void registerUser() async {
    final validationError = _validateFields();
    if (validationError != null) {
      _showSnackbar(validationError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _auth.register(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    } else {
      if (mounted) {
        _showSnackbar(_auth.error ?? 'Registration failed');
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Color(0xff1F41BB),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Create an account to chat\n with friends and family.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                MyTextfield(
                  controller: _usernameController,
                  hintText: "Username",
                  isPassword: false,
                ),
                const SizedBox(height: 8),
                MyTextfield(
                  controller: _emailController,
                  hintText: "Email",
                  isPassword: false,
                ),
                const SizedBox(height: 8),
                MyTextfield(
                  controller: _passwordController,
                  hintText: "Password",
                  isPassword: true,
                ),
                const SizedBox(height: 8),
                MyTextfield(
                  controller: _confirmpasswordController,
                  hintText: "Confirm Password",
                  isPassword: true,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  height: 60,
                  width: 357,
                  child: ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFF002DE3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign in now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1F41BB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isPassword,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 357,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          fillColor: const Color.fromARGB(255, 241, 241, 246),
          filled: true,
          hintText: hintText,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
