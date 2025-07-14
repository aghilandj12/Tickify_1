import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_form_page.dart'; // Make sure to create this page

class BookTicketsPage extends StatelessWidget {
  const BookTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final busCollection = FirebaseFirestore.instance.collection('buses');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select a Bus"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: busCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading buses"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final buses = snapshot.data!.docs;

            if (buses.isEmpty) {
              return const Center(
                child: Text("No buses found", style: TextStyle(fontSize: 18)),
              );
            }

            return ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final doc = buses[index];
                final data = doc.data() as Map<String, dynamic>;

                final String busNumber = data['busNumber'] ?? 'Unknown';
                final String from = data['from'] ?? 'From';
                final String to = data['to'] ?? 'To';
                final int availableSeats = data['availableSeats'] ?? 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_bus, color: Colors.orange, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                busNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            availableSeats > 0
                                ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$availableSeats seats",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Fully Booked",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$from ➝ $to",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: availableSeats > 0
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingFormPage(
                                    busId: doc.id,
                                    busData: data,
                                  ),
                                ),
                              );
                            }
                                : null, // disables the button if fully booked
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: availableSeats > 0 ? Colors.orange : Colors.grey,
                            ),
                            label: Text(
                              "Book Now",
                              style: TextStyle(
                                color: availableSeats > 0 ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
