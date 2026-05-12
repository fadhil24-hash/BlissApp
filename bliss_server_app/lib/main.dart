import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin_login.dart';

const Color blissGold = Color(0xFFD4AF37);
const Color blissBlack = Color(0xFF1A1A1A);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bliss Admin',
      theme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: blissBlack,
  primaryColor: blissGold,
  useMaterial3: true,

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: blissGold,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  ),
),
      home: const AdminLogin(),
    );
  }
}