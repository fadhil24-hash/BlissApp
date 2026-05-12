import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color blissGold = Color(0xFFC0832F);
const Color blissBlack = Color(0xFF101010);

class AdminOrderDetail extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const AdminOrderDetail({
    super.key,
    required this.orderId,
    required this.data,
  });
String _formatTime(Timestamp timestamp) {
  final date = timestamp.toDate();
  return "${date.day}/${date.month} "
         "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}
String _formatTimeOnly(Timestamp timestamp) {
  final date = timestamp.toDate();
  return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}

Widget _statusChip(String status) {
  IconData icon;
  Color color;

  switch (status) {
    case "Pending":
      icon = Icons.hourglass_empty;
      color = Colors.grey;
      break;
    case "Received":
      icon = Icons.receipt;
      color = Colors.blue;
      break;
    case "On Progress":
      icon = Icons.hourglass_top;
      color = Colors.orange;
      break;
    case "Done":
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    default:
      icon = Icons.info;
      color = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final items = (data['items'] ?? []) as List;

    return Scaffold(
      backgroundColor: blissBlack,
      appBar: AppBar(
        title: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        "Order ${orderId}",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    if (data['createdAt'] != null)
      Text(
        _formatTimeOnly(data['createdAt']),
        style: const TextStyle(
          color: blissGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
  ],
),
        backgroundColor: blissBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 USER
           FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: data['userEmail'])
      .limit(1)
      .get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text("User: ...", style: TextStyle(color: Colors.grey));
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
if (data['createdAt'] != null)
  if (data['createdAt'] != null)
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      _formatTime(data['createdAt']),
      style: const TextStyle(
        color: blissGold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
            // 🔥 STATUS
           _statusChip(data['status'] ?? "-"),

            const Divider(color: Colors.grey),
// 🔥 NOTE CUSTOMER
if (data['note'] != null && data['note'].toString().isNotEmpty)
  Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: blissGold.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: blissGold.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Customer Note",
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
            const SizedBox(height: 10),

            // 🔥 ITEMS
            const Text(
              "Items",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (items.isEmpty)
              const Text("No items", style: TextStyle(color: Colors.grey))
            else
             ...items.map((item) {
  final map = item as Map<String, dynamic>;

  final addOns = (map['addOns'] as List?)?.join(', ') ?? '-';

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          blissGold.withOpacity(0.12),
          Colors.transparent,
        ],
      ),
      border: Border.all(color: blissGold.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 TITLE + PRICE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              map['name'] ?? '',
              style: const TextStyle(
                color: blissGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${map['price']}K",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🔥 TYPE
        Text(
          "Type: ${map['size'] ?? '-'}",
          style: const TextStyle(color: Colors.grey),
        ),

        // 🔥 ICE + SUGAR
        if (map['c'] == "Food")
  const Text(
    "No customization",
    style: TextStyle(color: Colors.grey),
  )
else
  Text(
    "Ice: ${map['ice'] ?? '-'} | Sugar: ${map['sugar'] ?? '-'}",
    style: const TextStyle(color: Colors.grey),
  ),

        // 🔥 ADD ONS
        Text(
          "Add-ons: $addOns",
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 6),

        // 🔥 QTY
        Text(
          "Quantity: ${map['qty'] ?? 1}",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}),

            const SizedBox(height: 20),

            // 🔥 IMAGE PROOF
            const Text(
              "Payment Proof",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (data['imageUrl'] != null &&
                data['imageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
  child: Container(
    width: 320,
    height: 460,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: blissGold.withOpacity(0.3)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        data['imageUrl'],
        fit: BoxFit.cover,
      ),
    ),
  ),
),
              )
            else
              const Text(
                "No image uploaded",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 30),

            // 🔥 BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'status': 'On Progress'});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Order Processing")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blissGold,
                ),
                child: const Text("Process Order"),
              ),
            ),

            // 🔥 ACTION BUTTONS
const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {
      String current = data['status'];

      String next = "";

      if (current == "pending") next = "Received";
      else if (current == "Received") next = "On Progress";
      else if (current == "On Progress") next = "Done";
      else return;

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': next});
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: blissGold,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      data['status'] == "pending"
          ? "Accept Order"
          : data['status'] == "Received"
              ? "Start Cooking"
              : data['status'] == "On Progress"
                  ? "Mark Done"
                  : "Completed",
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),],
        ),
      ),
    );
  }
}