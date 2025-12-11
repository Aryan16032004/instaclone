import 'package:flutter/material.dart';


class GradientButton extends StatelessWidget {
final Widget child;
final VoidCallback onTap;
const GradientButton({required this.child, required this.onTap, Key? key}) : super(key: key);


@override
Widget build(BuildContext context) {
final gradient = LinearGradient(colors: [Color(0xFFf58529), Color(0xFFdd2a7b), Color(0xFF8134af)]);
return InkWell(
onTap: onTap,
child: Container(
padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
decoration: BoxDecoration(
gradient: gradient,
borderRadius: BorderRadius.circular(12),
),
child: Center(child: child),
),
);
}
}