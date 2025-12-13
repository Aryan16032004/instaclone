import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/masti_widgets.dart'; // Ensure this exists

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  
  bool _loading = false;
  String? _error;

  void _handleRegister() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    // Basic Validation
    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _error = "Please fill in ALL fields.");
      return;
    }
    if (password.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }

    setState(() { _loading = true; _error = null; });

    final auth = Provider.of<AuthService>(context, listen: false);
    
    // Call our new "Register All" function
    final res = await auth.registerAllDetails(
      email: email, 
      phone: phone, 
      username: username, 
      password: password
    );

    setState(() { _loading = false; });

    if (res != null) {
      setState(() => _error = res);
    } else {
      if (mounted) Navigator.pop(context); // Return to Login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Join Masti today!", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 30),

            // 1. Username
            MastiInput(
              hint: "Username",
              controller: _usernameCtrl,
              icon: Icons.person_outline,
            ),

            // 2. Email
            MastiInput(
              hint: "Email Address",
              controller: _emailCtrl,
              icon: Icons.email_outlined,
            ),

            // 3. Phone Number (Added!)
            MastiInput(
              hint: "Phone Number",
              controller: _phoneCtrl,
              prefixText: "+91 ▾ |  ",
            ),

            // 4. Password
            MastiInput(
              hint: "Password",
              controller: _pwdCtrl,
              isPassword: true,
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 30),

            _loading 
              ? const Center(child: CircularProgressIndicator(color: Colors.pink))
              : MastiGradientButton(
                  text: "Register & Login",
                  onTap: _handleRegister,
                ),

            const SizedBox(height: 20),
            const Center(child: Text("By registering, you agree to our Terms.", style: TextStyle(color: Colors.grey, fontSize: 11))),
          ],
        ),
      ),
    );
  }
}