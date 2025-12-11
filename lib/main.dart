import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

// ⚠️ PASTE YOUR KEYS HERE (Keep them safe)
const supabaseUrl = 'https://krykwduncongzmyyhpuw.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyeWt3ZHVuY29uZ3pteXlocHV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0MzYwMjgsImV4cCI6MjA4MTAxMjAyOH0.xwugcvtD61K5zMaBA1Va02NEu4WgV6Sekt7vbkQ7dwM';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Insta Clone',
            // DARK THEME + GRADIENT ACCENTS
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFC13584), // Insta-like pink/purple
                secondary: Color(0xFF833AB4),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                iconTheme: IconThemeData(color: Colors.white),
              ),
            ),
            home: auth.isLoggedIn ? HomeScreen() : LoginScreen(),
            routes: {
              '/login': (_) => LoginScreen(),
              '/register': (_) => RegisterScreen(),
              '/home': (_) => HomeScreen(),
            },
          );
        },
      ),
    );
  }
}