import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_home.dart';

const Color blissGold = Color(0xFFC0832F);
const Color blissBlack = Color(0xFF101010);

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _idController.text.trim(),
          password: _passController.text.trim(),
        );

        // 🔥 VALIDASI ADMIN
        if (userCredential.user!.email != "admin@bliss.com") {
          await FirebaseAuth.instance.signOut();
          throw Exception("Not admin");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const AdminHome()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed")),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blissBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.fastfood,
                    size: 80, color: blissGold),

                const SizedBox(height: 20),

                const Text(
                  "Admin Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon:
                        const Icon(Icons.person, color: blissGold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _passController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon:
                        const Icon(Icons.lock, color: blissGold),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 25),

                _isLoading
                    ? const CircularProgressIndicator(color: blissGold)
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blissGold,
                          minimumSize:
                              const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}