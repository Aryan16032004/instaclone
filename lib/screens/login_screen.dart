import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/masti_widgets.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Generic controller for Phone/Email/Username
  final _inputController = TextEditingController(); 
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  void _handleSmartLogin() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter credentials");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final auth = Provider.of<AuthService>(context, listen: false);
    
    // Call our new SMART LOGIN function
    final error = await auth.smartLogin(input, password);
    
    setState(() { _isLoading = false; });

    if (error != null) {
      setState(() => _errorMessage = error);
    }
    // If success, the main.dart stream listener will automatically switch to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFC13584), Color(0xFF833AB4)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 30),
                
                const Text("Log in", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Enter your credentials to continue", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // SMART INPUT: Handles Phone, Email, or Username
                MastiInput(
                  hint: "Phone / Email / Username", 
                  controller: _inputController,
                  icon: Icons.person,
                ),

                // Password Input
                MastiInput(
                  hint: "Password", 
                  controller: _passwordController,
                  isPassword: true,
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: 20),

                // Login Button
                _isLoading 
                  ? const CircularProgressIndicator(color: Colors.pink)
                  : MastiGradientButton(
                      text: "Log in",
                      onTap: _handleSmartLogin, // 👈 Calls smart logic
                    ),
                
                const SizedBox(height: 20),
                
                // Navigation to Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text("Sign up", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Social Row
                const Text("Or log in by", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginButton(icon: FontAwesomeIcons.facebookF, color: Colors.blue[800]!, onTap: () {}),
                    const SizedBox(width: 20),
                    SocialLoginButton(icon: FontAwesomeIcons.google, color: Colors.white, onTap: () {}),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Powered by masti.video", style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}