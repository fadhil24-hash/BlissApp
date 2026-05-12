import 'package:flutter/material.dart';
import 'dart:io'; // Needed for File
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb check
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> uploadToCloudinary(File imageFile) async {
  final url = Uri.parse("https://api.cloudinary.com/v1_1/dais1327r/image/upload");

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = 'flutter_upload'
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await response.stream.bytesToString();
    final data = jsonDecode(res);
    return data['secure_url'];
  } else {
    print("UPLOAD ERROR: ${response.statusCode}");
    return null;
  }
}

// Bliss Theme Colors
const Color blissGold = Color(0xFFD4AF37); 
const Color blissBlack = Color(0xFF1A1A1A);

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;

  const PaymentScreen({super.key, required this.totalAmount, required this.orderId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _proofImage; // This stores the file for your Redmi phone
  XFile? _webImage;  // This stores the file for Chrome
  final ImagePicker _picker = ImagePicker();

Uint8List? _webImageBytes;
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();

      setState(() {
        _webImage = image;
        _webImageBytes = bytes;
      });
    } else {
      setState(() {
        _proofImage = File(image.path);
      });
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Payment", style: TextStyle(color: Colors.white)),
        backgroundColor: blissBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text("Total to Pay", style: TextStyle(color: Colors.grey, fontSize: 16)),
            Text(
              "${widget.totalAmount.toStringAsFixed(0)}K",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: blissGold),
            ),
            const SizedBox(height: 30),

            // QRIS IMAGE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/qris_payment.png', 
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              "1. Scan QRIS and Pay\n2. Take a Screenshot\n3. Upload the Proof below",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 30),

            // UPLOAD BOX
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: (_proofImage == null && _webImageBytes == null) ? blissGold : Colors.green,
                    width: 2,
                  ),
                ),
                child: (_proofImage == null && _webImageBytes == null)
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: blissGold, size: 50),
                          SizedBox(height: 10),
                          Text("Upload Payment Screenshot", style: TextStyle(color: blissGold)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb 
                           ?  Image.memory(
                    _webImageBytes!,
                    fit: BoxFit.cover,
                  )
                
              
            : Image.file(
                _proofImage!,
                fit: BoxFit.cover,
              ),),
              ),
            ),

            const SizedBox(height: 40),

            // SUBMIT BUTTON
            ElevatedButton(
             onPressed: () async {
  print("STEP 1: klik");

  String? imageUrl;

if (kIsWeb) {
  print("UPLOAD WEB");

  final url = Uri.parse("https://api.cloudinary.com/v1_1/dais1327r/image/upload");

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = 'flutter_upload'
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        _webImageBytes!,
        filename: 'upload.jpg',
      ),
    );

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await response.stream.bytesToString();
    final data = jsonDecode(res);
    imageUrl = data['secure_url'];
  } else {
    print("UPLOAD WEB ERROR");
    return;
  }

} else {
  print("UPLOAD MOBILE");
  imageUrl = await uploadToCloudinary(_proofImage!);
}

if (imageUrl == null) {
  print("UPLOAD GAGAL");
  return;
}

print("URL CLOUDINARY: $imageUrl");

    print("STEP 4: upload selesai");

    
    print("STEP 5: url = $imageUrl");

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId) // ID fix kamu
        .update({
      'imageUrl': imageUrl,
      'status': 'paid',
    });

    print("STEP 6: firestore update");

    globalCart.clear(); // reset cart (opsional tapi penting)

if (!context.mounted) return; // 🔥 safety async

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const OrderStatusScreen(),
  ),
);

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Payment Success"),
    backgroundColor: Colors.green,
  ),
);

  },
              style: ElevatedButton.styleFrom(
                backgroundColor: (_proofImage == null && _webImageBytes == null) ? Colors.grey : blissGold,
                minimumSize: const Size(double.infinity, 50), // Tinggi tombol dikurangi dikit
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                (_proofImage == null && _webImageBytes == null) ? "UPLOAD PROOF FIRST" : "FINISH ORDER",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

