import 'payment_screen.dart';
import 'package:flutter/material.dart';
import 'bliss_cafe.dart';
import 'bliss_burger.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BlissApp());
}

// --- Brand Identity ---
const Color blissGold = Color(0xFFC0832F);
const Color blissBlack = Color(0xFF101010);

// --- 1. Security & Data Models ---

// Simulated Database



String? globalUserName;
String? globalUserEmail;

// --- 2. Cart Logic (UPDATED) ---
class CartItem {
  final String name;
  final String size; // Medium, Large, or Standard
  final String ice;
  final String sugar;
  final List<String> addOns;
  final String category;
  final double basePrice;
  int quantity;

  CartItem({
    required this.name,
    required this.size,
    required this.ice,
    required this.sugar,
    required this.addOns,
    required this.category,
    required this.basePrice,
    this.quantity = 1,
  });

  double get totalPrice => (basePrice + (addOns.length * 5)) * quantity;

  // For checking if two items are identical for merging
  bool isSameAs(CartItem other) {
    return name == other.name &&
        size == other.size &&
        ice == other.ice &&
        sugar == other.sugar &&
        addOns.join(',') == other.addOns.join(',');
  }
}

class OrderHistory {
  final String orderId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderTime; // Pastikan ini ada
  String status;

  OrderHistory({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.orderTime, // Pastikan ini ada
    this.status = "Received",
  });
}

class ChatMessage {
  final String text;
  final bool isMe; // true jika dari Consumer, false jika dari Admin
  final DateTime time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

List<ChatMessage> chatSession = [
  ChatMessage(text: "Hi there! How can we help you with your order today?", isMe: false, time: DateTime.now()),
];

List<CartItem> globalCart = [];
List<OrderHistory> activeOrders = [];
List<OrderHistory> pastOrders = [];



class BlissApp extends StatelessWidget {
  const BlissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bliss App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: blissGold,
        scaffoldBackgroundColor: blissBlack,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// --- 3. Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
void initState() {
  super.initState();
  _loadSavedLogin();
}

  Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _passController.text.trim(),
      );

      globalUserEmail = userCredential.user!.email;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
       globalUserName = userDoc['name'];
        final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setString('savedEmail', _idController.text.trim());
        await prefs.setString('savedPassword', _passController.text.trim());
      } else {
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
      }



      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const SelectionScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed")),
      );
    }

    setState(() => _isLoading = false);
  }
}
Future<void> _loadSavedLogin() async {
  final prefs = await SharedPreferences.getInstance();

  final savedEmail = prefs.getString('savedEmail');
  final savedPassword = prefs.getString('savedPassword');

  if (savedEmail != null && savedPassword != null) {
    setState(() {
      _idController.text = savedEmail;
      _passController.text = savedPassword;
      _rememberMe = true;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.fastfood, size: 80, color: blissGold),
                const SizedBox(height: 20),
                const Text("Login to Bliss", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: "Email", 
                    prefixIcon: const Icon(Icons.person, color: blissGold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: blissGold),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                Row(
                  children: [
                    Checkbox(value: _rememberMe, activeColor: blissGold, onChanged: (v) => setState(() => _rememberMe = v!)),
                    const Text("Remember Me"),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ForgotPasswordScreen())),
                      child: const Text("Forgot Password?", style: TextStyle(color: blissGold)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: blissGold)
                    : ElevatedButton(
                        onPressed: _handleLogin, 
                        style: ElevatedButton.styleFrom(backgroundColor: blissGold, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())),
                  child: const Text("New here? Create Bliss Account", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 4. Sign Up Screen ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _termsAccepted = false;
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
  if (!_formKey.currentState!.validate()) return;

  if (!_termsAccepted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Accept Terms & Conditions")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
    );

    // optional: simpan ke firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Created")),
    );

    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    String message = "Signup failed";

    if (e.code == 'email-already-in-use') {
      message = "Email already used";
    } else if (e.code == 'weak-password') {
      message = "Password too weak";
    } else if (e.code == 'invalid-email') {
      message = "Invalid email";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong")),
    );
  }

  setState(() => _isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 15),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email"), validator: (v) {
  if (v == null || v.isEmpty) return "Required";
  if (!v.contains('@')) return "Invalid Email";
  return null;
}),
              const SizedBox(height: 15),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), validator: (v) => v!.length < 10 ? "Invalid Phone" : null),
              const SizedBox(height: 15),
             
              const SizedBox(height: 15),
              TextFormField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Password"),validator: (v) {
  if (v == null || v.length < 6) return "Min 6 characters";
  return null;
}),
              const SizedBox(height: 15),
              TextFormField(controller: _confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: "Confirm Password"), validator: (v) => v != _passController.text ? "No match" : null),
              CheckboxListTile(
                title: const Text("I accept Terms & Conditions", style: TextStyle(fontSize: 12)),
                value: _termsAccepted,
                activeColor: blissGold,
                onChanged: (v) => setState(() => _termsAccepted = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleSignUp, style: ElevatedButton.styleFrom(backgroundColor: blissGold, minimumSize: const Size(double.infinity, 50)), child: const Text("Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 5. Forgot Password ---
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendReset() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset email sent! check inbox 📩")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send reset email")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: sendReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blissGold,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Send Reset Email"),
                  ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Password")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const TextField(obscureText: true, decoration: InputDecoration(labelText: "New Password")),
            const SizedBox(height: 20),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: "Confirm New Password")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: blissGold, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Reset Password"),
            )
          ],
        ),
      ),
    );
  }
}

// --- 6. Selection Screen ---
class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
           Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: blissGold),
                onPressed: () {
                  // Ini yang membuat icon bisa ditekan
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const OrderStatusScreen()),
                  );
                },
              ),
              if (activeOrders.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${activeOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                )
            ],
          ),

           IconButton(
            icon: const Icon(Icons.history, color: blissGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const OrderHistoryScreen()),
              );
            },
          ),

          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.shopping_cart, color: blissGold),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
                    setState(() {}); 
                  }),
              if (globalCart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${globalCart.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()))),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 60, color: blissGold),
            Text("Welcome, $globalUserName!", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildSelectionBtn(context, "Bliss Burger", Icons.lunch_dining),
            const SizedBox(height: 20),
            _buildSelectionBtn(context, "Bliss Cafe", Icons.local_cafe),
          ],
        ),
      ),
      
    );
  }
  

  Widget _buildSelectionBtn(BuildContext context, String title, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (c) => MenuScreen(shopName: title)));
        setState(() {}); // Refresh UI on return
      },
      icon: Icon(icon, color: Colors.black),
      label: Text(title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: blissGold, fixedSize: const Size(280, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    );
  }
}

// --- 7. Menu Screen (CLEANED UP) ---
class MenuScreen extends StatefulWidget {
  final String shopName;
  const MenuScreen({super.key, required this.shopName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // THE GIANT LIST IS GONE! 
  // We now pick the correct list from your new files (bliss_burger.dart or bliss_cafe.dart)
  late List<Map<String, dynamic>> fullMenu;

  @override
  void initState() {
    super.initState();
    // This looks at which button you clicked and grabs the correct list
    fullMenu = (widget.shopName == "Bliss Cafe") ? blissCafeMenu : blissBurgerMenu;
  }

  void _showCustomizationDialog(Map<String, dynamic> item) {
    bool isDrink = item['c'] == "Drink" 
            || item['c'] == "Coffee" 
            || item['c'] == "Beverages" 
            || item['c'] == "Tea";
    Map<String, int> prices = Map<String, int>.from(item['prices']);
    String selectedSize = prices.keys.first;
    String selectedIce = "Normal Ice";
    String selectedSugar = "Normal Sugar";
    int quantity = 1;
    List<String> selectedAddOns = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: blissBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double basePrice = prices[selectedSize]!.toDouble();
            double currentTotalPrice = (basePrice + (selectedAddOns.length * 5)) * quantity;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['n'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: blissGold)),
                    const Divider(height: 30),

                    if (prices.length > 1) ...[
                      const Text("Select Size:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: prices.keys.map((size) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(size),
                              selected: selectedSize == size,
                              selectedColor: blissGold,
                              onSelected: (val) => setModalState(() => selectedSize = size),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (isDrink) ...[
                    const Text("Ice Level:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10,
                      children: ["No Ice", "Less Ice", "Normal Ice"].map((opt) {
                        return ChoiceChip(
                          label: Text(opt),
                          selected: selectedIce == opt,
                          onSelected: (val) => setModalState(() => selectedIce = opt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text("Sugar Level:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10,
                      children: ["No Sugar", "Less Sugar", "Normal Sugar"].map((opt) {
                        return ChoiceChip(
                          label: Text(opt),
                          selected: selectedSugar == opt,
                          onSelected: (val) => setModalState(() => selectedSugar = opt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text("Add-ons (+5K each):", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...["Espresso", "Milk (80ml)", "Oat Milk change", "Oreo Crumble", "Cream (20g)"].map((addon) {
                      return CheckboxListTile(
                        title: Text(addon, style: const TextStyle(fontSize: 14)),
                        value: selectedAddOns.contains(addon),
                        activeColor: blissGold,
                        dense: true,
                        onChanged: (val) {
                          setModalState(() {
                            val! ? selectedAddOns.add(addon) : selectedAddOns.remove(addon);
                          });
                        },
                      );
                    }).toList(),
                    ] else ...[
                      const Text("No customizations available for food items.", style: TextStyle(color: Colors.grey)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Quantity:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: blissGold), onPressed: () {
                              if (quantity > 1) setModalState(() => quantity--);
                            }),
                            Text("$quantity", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add_circle_outline, color: blissGold), onPressed: () {
                              setModalState(() => quantity++);
                            }),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: blissGold, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        CartItem newItem = CartItem(
                          name: item['n'],
                          size: selectedSize,
                          ice: selectedIce,
                          sugar: selectedSugar,
                          addOns: List.from(selectedAddOns),
                          basePrice: basePrice,
                          category: item['c']??"Food ",
                          quantity: quantity,
                        );
                        int index = globalCart.indexWhere((existing) => existing.isSameAs(newItem));
                        if (index != -1) {
                          globalCart[index].quantity += quantity;
                        } else {
                          globalCart.add(newItem);
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart!"), backgroundColor: blissGold));
                        setState(() {});
                      },
                      child: Text("Add to Cart - ${currentTotalPrice.toStringAsFixed(0)}K", style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This filters the menu based on the shop you are in
    final List<Map<String, dynamic>> items = widget.shopName == "Bliss Cafe" 
        ? fullMenu.where((e) => e['c'] != "Food").toList() 
        : fullMenu.where((e) => e['c'] == "Food").toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName, style: const TextStyle(color: blissGold)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart, color: blissGold), onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
                setState(() {});
              }),
              if (globalCart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${globalCart.length}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          String priceDisplay = items[index]['prices'].values.join(' / ') + "K";
          return Card(
            color: Colors.white.withAlpha(15), 
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(items[index]['n'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(items[index]['c'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: Text(priceDisplay, style: const TextStyle(color: blissGold, fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => _showCustomizationDialog(items[index]),
            ),
          );
        },
      ),
    );
  }
}

// --- 8. Cart Screen (FULL ORDER REVIEW) ---
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get total => globalCart.fold(0, (sum, item) => sum + item.totalPrice);
final TextEditingController noteController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Order", style: TextStyle(color: blissGold))),
      body: globalCart.isEmpty 
        ? const Center(child: Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)))
        : Column(
            children: [
              Expanded(
  child: ListView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: globalCart.length,
    itemBuilder: (context, index) {
      final item = globalCart[index];

      return Card(
        color: const Color.fromARGB(255, 218, 82, 82).withAlpha(10),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      item.name,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: blissGold,
      ),
    ),

    Row(
      children: [
        Text(
          "${item.totalPrice.toStringAsFixed(0)}K",
          style: const TextStyle(fontSize: 16),
        ),

        IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove item?"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                globalCart.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  },
),
      ],
    ),
  ],
),

    const SizedBox(height: 5),

    // SIZE / TYPE (Food & Drink)
    Text(
      "Type: ${item.size}",
      style: const TextStyle(color: Colors.grey, fontSize: 13),
    ),

    // DRINK ONLY (ice & sugar)
    if(item.category != "Food") ...[
    if (item.ice != "-" || item.sugar != "-") ...[
      Text(
        "Ice: ${item.ice} | Sugar: ${item.sugar}",
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    ],
    ],

    // ADD ONS (kalau ada)
    if (item.addOns.isNotEmpty) ...[
      Text(
        "Add-ons: ${item.addOns.join(', ')}",
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    ],

    const SizedBox(height: 5),

    // QUANTITY
    Text(
      "Quantity: ${item.quantity}",
      style: const TextStyle(color: Colors.grey),
    ),
  ],
),
        ),
      );
    },
  ),
),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [TextField(
      controller: noteController,
      maxLines: 2,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Add note for your order...",
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: blissGold.withOpacity(0.3)),
        ),
      ),
    ),

    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total to Pay", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("${total.toStringAsFixed(0)}K", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: blissGold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: blissGold, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                     onPressed: () async {
  // 🔥 generate custom ID
  final orderId = await generateOrderId();
  await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .set({
    'items': globalCart.map((item) => {
      'name': item.name,
      'price': item.basePrice,
      'qty': item.quantity,
      'size': item.size,
      'ice': item.category == "Food" ? null : item.ice,
      'sugar': item.category == "Food" ? null : item.sugar,
      'addons': item.addOns,
      'category': item.category,
    }).toList(),

    'totalPrice': total,
    'status': 'pending',
    'userEmail': globalUserEmail,
    'createdAt': Timestamp.now(),
    'imageUrl': null,
    'isHistory': false,
    'note': noteController.text.trim(),
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentScreen(
        totalAmount: total,
        orderId: orderId, // 🔥 pakai custom ID
      ),
    ),
  );
},

                      child: const Text("CHECKOUT NOW", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            ],
          ),
    );
  }
}

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

      @override

      Widget build(BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.black, // Memastikan background tetap gelap
          appBar: AppBar(
            title: const Text("Track My Order", style: TextStyle(color: blissGold)),
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
         body: StreamBuilder(
  stream: FirebaseFirestore.instance
    .collection('orders')
    .where('userEmail', isEqualTo: globalUserEmail)
    .where('isHistory', isEqualTo: false)// 🔥 TAMBAH INI
    .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
      return const Center(
        child: Text(
          "No active orders",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();

        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        return Column(
          children: [
            _buildProgressIndicator(data['status'] ?? "Pending"),
            const SizedBox(height: 25),

            Card(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
  child: Text(
    "Order ${docs[index].id}",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    maxLines: 2, // 🔥 Boleh turun ke baris kedua
    overflow: TextOverflow.ellipsis, // kalau masih kepanjangan, kasih ...
  ),
),
                        _statusBadge(data['status'] ?? "Pending"),
                      ],
                    ),

                    const Divider(height: 30),

                    ...items.map((item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item['qty']}x ${item['name']}"),
                            Text("${item['price']}K"),
                          ],
                        )),

                    const Divider(height: 30),
if (data['note'] != null && data['note'].toString().isNotEmpty)
  Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: blissGold.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Note",
          style: TextStyle(
            color: blissGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data['note'],
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount"),
                        Text("${data['totalPrice']}K",
                            style: const TextStyle(
                                color: blissGold,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                   const SizedBox(height: 15),

if (data['status'] == "Done")
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: blissGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(docs[index].id)
            .update({'isHistory': true});
      },
      child: const Text(
        "Send to History",
        style: TextStyle(color: Colors.black),
      ),
    ),
  ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  },
),);
      }

      // Widget untuk garis progress (Received -> Progress -> Complete)
      Widget _buildProgressIndicator(String status) {
        int currentStep = 0;
        // Urutan: Pending (0) -> Received (1) -> On Progress (2) -> Done (3)
        if (status == "Pending") currentStep = 0;
        if (status == "Received") currentStep = 1;
        if (status == "On Progress") currentStep = 2;
        if (status == "Done" || status == "Complete") currentStep = 3;

        return Row(
          children: [
            _stepIcon(Icons.hourglass_empty, "Pending", currentStep >= 0),
            _line(currentStep >= 1),
            _stepIcon(Icons.receipt, "Received", currentStep >= 1),
            _line(currentStep >= 2),
            _stepIcon(Icons.hourglass_top, "On Progress", currentStep >= 2),
            _line(currentStep >= 3),
            _stepIcon(Icons.check_circle, "Done", currentStep >= 3),
          ],
        );
      }

  Widget _stepIcon(IconData icon, String label, bool isActive) {
      return Column(
        children: [
          // Jika statusnya Pending dan sedang aktif, tampilkan Loading berputar
          // Jika tidak, tampilkan CircleAvatar biasa dengan icon
          (label == "Pending" && isActive)
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(blissGold),
                      ),
                      Icon(icon, size: 16, color: blissGold),
                    ],
                  ),
                )
              : CircleAvatar(
                  radius: 20, // Ukuran disesuaikan agar konsisten
                  backgroundColor: isActive ? blissGold : Colors.grey[800],
                  child: Icon(
                    icon, 
                    size: 20, 
                    color: isActive ? Colors.black : Colors.grey
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? blissGold : Colors.grey
            ),
          ),
        ],
      );
    }
  Widget _line(bool isActive) => Expanded(
    child: Container(height: 2, color: isActive ? blissGold : Colors.grey[800]),
  );

      Widget _statusBadge(String status) {
      Color badgeColor;
      
      // Tentukan warna berdasarkan status baru termasuk status Pending
      switch (status) {
        case "Pending":
          badgeColor = Colors.grey; // Abu-abu untuk menunggu konfirmasi/jaringan lambat
          break;
        case "Received":
          badgeColor = Colors.blue; // Biru untuk pesanan sudah diterima admin
          break;
        case "On Progress":
          badgeColor = Colors.orange; // Oranye untuk pesanan sedang diproses
          break;
        case "Done":
        case "Complete":
          badgeColor = Colors.green; // Hijau untuk pesanan selesai
          break;
        default:
          badgeColor = Colors.grey;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.15), // Background transparan tipis
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withOpacity(0.4), 
            width: 1,
          ), // Garis tepi halus agar terlihat profesional di mode gelap
        ),
        child: Text(
          status,
          style: TextStyle(
            color: badgeColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History",
            style: TextStyle(color: blissGold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('orders')
      .where('userEmail', isEqualTo: globalUserEmail)
      .where('isHistory', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
      return const Center(child: Text("No history yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        return Card(
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order ${docs[index].id}"),

                const Divider(),

                ...items.map((item) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${item['qty']}x ${item['name']}"),
                        Text("${item['price']}K"),
                      ],
                    )),

                const Divider(),

                Text("Total: ${data['totalPrice']}K",
                    style: const TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        );
      },
    );
  },
)
    );
  }
}
Future<String> generateOrderId() async {
  final counterRef = FirebaseFirestore.instance
      .collection('counters')
      .doc('orders');

  return FirebaseFirestore.instance.runTransaction((tx) async {
    final snapshot = await tx.get(counterRef);

    int current = snapshot.exists ? snapshot['value'] : 0;
    int next = current + 1;

    tx.set(counterRef, {'value': next});

    return "BLISS-$next";
  });
}
