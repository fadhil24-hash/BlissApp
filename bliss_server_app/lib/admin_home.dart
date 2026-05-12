import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_order_detail.dart';
import 'admin_login.dart';
import 'admin_history.dart';

const Color blissGold = Color(0xFFC0832F);
const Color blissBlack = Color(0xFF101010);

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [IconButton(
    icon: const Icon(Icons.history),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminHistoryScreen(),
        ),
      );
    },
  ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminLogin(),
                ),
              );
            },
          ),
        ],
      ),

      // 🔥 INI YANG KAMU KURANG
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('isHistory', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No Orders"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              // 🔥 UI YANG KAMU TANYA → TARUH DI SINI
              return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrderDetail(
          orderId: doc.id,
          data: data,
        ),
      ),
    );
  },
  child: Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.all(15),
   decoration: BoxDecoration(
  color: data['status'] == "Done"
      ? blissBlack
      : blissGold.withOpacity(0.08),
      borderRadius: BorderRadius.circular(15),
     border: Border.all(
  color: data['status'] == "Done"
      ? Colors.grey.withOpacity(0.2)
      : blissGold,
),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        "Order ${doc.id}",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: blissGold.withOpacity(0.15),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    _formatTimeOnly(data['createdAt']),
    style: const TextStyle(
      color: blissGold,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),
  ],
),
        const SizedBox(height: 5),

       FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: data['userEmail'])
      .limit(1)
      .get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const SizedBox();
    }

    final user =
        snapshot.data!.docs.first.data() as Map<String, dynamic>;

    return Text(
  user['name'] ?? "-",
  style: const TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
);
  },
),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: blissGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            data['status'] ?? 'pending',
            style: const TextStyle(color: blissGold),
          ),
        ),

        if (data['note'] != null && data['note'] != "")
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Note: ${data['note']}",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    ),
  ),
);
            },
          );
        },
      ),
    );
  }
}
String _formatTimeOnly(Timestamp timestamp) {
  final date = timestamp.toDate();
  return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}