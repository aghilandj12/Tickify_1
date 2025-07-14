import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBusPage extends StatefulWidget {
  const AddBusPage({super.key});

  @override
  State<AddBusPage> createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  final busNumberController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final regNoController = TextEditingController();
  final seatsController = TextEditingController();
  final routeController = TextEditingController();
  final stoppingPointsController = TextEditingController();

  void saveBus() async {
    final busNumber = busNumberController.text.trim();
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final regNo = regNoController.text.trim();
    final seatsText = seatsController.text.trim();
    final route = routeController.text.trim();
    final stoppingPointsText = stoppingPointsController.text.trim();

    if (busNumber.isEmpty || from.isEmpty || to.isEmpty || regNo.isEmpty || seatsText.isEmpty || route.isEmpty || stoppingPointsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    try {
      final int seats = int.parse(seatsText);
      final List<String> stoppingPoints = stoppingPointsText.split(',').map((e) => e.trim()).toList();

      await FirebaseFirestore.instance.collection('buses').add({
        'busNumber': busNumber,
        'busnumber': 'Bus #$busNumber',
        'from': from,
        'to': to,
        'regNo': regNo,
        'availableSeats': seats,
        'route': route,
        'stoppingPoints': stoppingPoints,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bus added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add bus: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Bus"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            buildField("Bus Number (e.g., 1)", busNumberController),
            const SizedBox(height: 16),
            buildField("From (e.g., cbe)", fromController),
            const SizedBox(height: 16),
            buildField("To (e.g., clg)", toController),
            const SizedBox(height: 16),
            buildField("Registration Number", regNoController),
            const SizedBox(height: 16),
            buildField("Available Seats (For Hostelers)", seatsController, inputType: TextInputType.number),
            const SizedBox(height: 16),
            buildField("Route Description", routeController),
            const SizedBox(height: 16),
            buildField("Stopping Points (comma separated)", stoppingPointsController),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveBus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Add Bus"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.orange.shade50,
      ),
    );
  }
}
