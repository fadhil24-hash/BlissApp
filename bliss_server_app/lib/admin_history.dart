import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_order_detail.dart';

const Color blissGold = Color(0xFFC0832F);
const Color blissBlack = Color(0xFF101010);

class AdminHistoryScreen extends StatelessWidget {
  const AdminHistoryScreen({super.key});

  String formatTime(Timestamp timestamp) {
    final d = timestamp.toDate();
    return "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blissBlack,
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: blissBlack,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('isHistory', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {

  // 🔴 ERROR HANDLING (WAJIB)
  if (snapshot.hasError) {
    return Center(
      child: Text(
        "Error: ${snapshot.error}",
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  // ⏳ LOADING
  if (!snapshot.hasData) {
    return const Center(child: CircularProgressIndicator());
  }

  final docs = snapshot.data!.docs;

  // 📭 KOSONG
  if (docs.isEmpty) {
    return const Center(
      child: Text(
        "No history yet",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // 📦 LIST DATA
  return ListView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: docs.length,
    itemBuilder: (context, index) {
      final data = docs[index].data() as Map<String, dynamic>;

      return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrderDetail(
          orderId: docs[index].id,
          data: data,
        ),
      ),
    );
  },
  child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: blissGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ${docs[index].id}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              data['userEmail'] ?? "-",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            if (data['createdAt'] != null)
              Text(
                formatTime(data['createdAt']),
                style: const TextStyle(
                  color: blissGold,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Completed",
                style: TextStyle(color: Colors.green),
              ),
            ),

            if (data['note'] != null &&
                data['note'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Note: ${data['note']}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ));
    },
  );
},
      ),
    );
  }
}