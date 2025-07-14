import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewTicketsPage extends StatelessWidget {
  final String phoneNumber;

  const ViewTicketsPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final ticketsRef = FirebaseFirestore.instance
        .collection('tickets')
        .where('phone', isEqualTo: phoneNumber)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ticketsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading tickets"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data?.docs ?? [];

          if (tickets.isEmpty) {
            return const Center(child: Text("No tickets found."));
          }

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final data = tickets[index].data() as Map<String, dynamic>;
              final Timestamp ts = data['timestamp'];
              final DateTime dt = ts.toDate();
              final String ticketId = data['ticketId'] ?? 'Unknown';
              final String status = data['status'] ?? 'valid';

              final Color bgColor =
              (status == 'used') ? Colors.grey.shade200 : Colors.green.shade50;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${data['from']} ➝ ${data['to']}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bus: ${data['busNumber']}  |  Name: ${data['name']}",
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            "Date: ${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const Divider(height: 24, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Ticket ID", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(ticketId, style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: $status",
                                    style: TextStyle(
                                      color: (status == 'used') ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "Ticket QR",
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 16),
                                            QrImageView(
                                              data: 'ticketId:$ticketId',
                                              size: 250,
                                            ),
                                            const SizedBox(height: 16),
                                            Text("Ticket ID: $ticketId"),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Status: $status",
                                              style: TextStyle(
                                                color: (status == 'used') ? Colors.red : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: QrImageView(
                                  data: 'ticketId:$ticketId',
                                  size: 80,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Decorative cutouts on both sides
                    Positioned(
                      top: 40,
                      left: -8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: -8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
