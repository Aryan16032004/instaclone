import 'package:flutter/material.dart';

class MastiInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;
  final String? prefixText;

  const MastiInput({
    super.key, 
    required this.hint, 
    required this.controller, 
    this.isPassword = false,
    this.icon,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark grey background
        borderRadius: BorderRadius.circular(30), // Pill shape
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: prefixText != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 14),
                  child: Text(prefixText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ) 
              : (icon != null ? Icon(icon, color: Colors.grey) : null),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: Colors.grey) : null, // Static for now
        ),
      ),
    );
  }
}

class MastiGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color> colors;

  const MastiGradientButton({
    super.key, 
    required this.text, 
    required this.onTap,
    this.colors = const [Color(0xFFFF00CC), Color(0xFF333399)], // Pink to Deep Blue
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30), // Pill shape
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SocialLoginButton({super.key, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}