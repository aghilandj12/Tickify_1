import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusInfoPage extends StatelessWidget {
  const BusInfoPage({super.key});

  void _showRoutePopup(BuildContext context, String busNumber, List<dynamic> stops) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Route for $busNumber",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (stops.isEmpty)
                const Text("No stopping points available.")
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stops.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(stops[index].toString()),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busCollection = FirebaseFirestore.instance.collection('buses');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bus Info"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: busCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error loading buses"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final buses = snapshot.data!.docs;

            if (buses.isEmpty) {
              return const Center(child: Text("No buses found", style: TextStyle(fontSize: 18)));
            }

            return ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final doc = buses[index];
                final data = doc.data() as Map<String, dynamic>;

                final List<dynamic> stops = data['stoppingPoints'] ?? [];

                return GestureDetector(
                  onTap: () => _showRoutePopup(context, data['busNumber'] ?? 'Bus', stops),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.grey[100],
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bus, size: 32, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "${data['busNumber'] ?? 'N/A'} - ${data['from']} ➝ ${data['to']}",
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text("Reg No: ${data['regNo'] ?? 'N/A'}"),
                          Text("Available Seats: ${data['availableSeats'] ?? 'N/A'}"),
                        ],
                      ),
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
