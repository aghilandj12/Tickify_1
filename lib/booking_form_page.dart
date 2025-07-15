import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingFormPage extends StatefulWidget {
  final String busId;
  final Map<String, dynamic> busData;

  const BookingFormPage({
    super.key,
    required this.busId,
    required this.busData,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _phoneController = TextEditingController();
  int _ticketCount = 1;
  String? _userPhone = 'unknown';

  late Razorpay _razorpay;
  bool _paymentSuccess = false;
  String? _ticketId;

  int get totalAmount => _ticketCount * 50;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _fetchPhoneNumber();
  }

  Future<void> _fetchPhoneNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null && doc.data()!.containsKey('phone')) {
          setState(() {
            _userPhone = doc.data()!['phone'];
          });
        } else {
          print("Phone number not found in Firestore.");
        }
      } catch (e) {
        print("Error fetching phone: $e");
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final ticketId = DateTime.now().millisecondsSinceEpoch.toString();

    if (_userPhone == "unknown") {
      _userPhone = _phoneController.text.trim();
    }

    final ticketData = {
      'ticketId': ticketId,
      'name': _nameController.text.trim(),
      'roll': _rollController.text.trim(),
      'phone': _userPhone,
      'busId': widget.busId,
      'busNumber': widget.busData['busNumber'],
      'from': widget.busData['from'],
      'to': widget.busData['to'],
      'tickets': _ticketCount,
      'amountPaid': totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('tickets').doc(ticketId).set(ticketData);

    final busRef = FirebaseFirestore.instance.collection('buses').doc(widget.busId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(busRef);
      final currentSeats = snapshot['availableSeats'] ?? 0;
      if (currentSeats >= _ticketCount) {
        transaction.update(busRef, {'availableSeats': currentSeats - _ticketCount});
      }
    });

    setState(() {
      _paymentSuccess = true;
      _ticketId = ticketId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Success! Ticket generated.")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment failed")));
  }

  void _startPayment() {
    if (_userPhone == "unknown") {
      _userPhone = _phoneController.text.trim();
    }

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
      'amount': totalAmount * 100,
      'name': 'Tickify',
      'description': 'Bus Ticket',
      'prefill': {
        'contact': _userPhone ?? '',
        'name': _nameController.text.trim(),
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    _razorpay.open(options);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _rollController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.busData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Confirmation"),
        backgroundColor: Colors.orange,
      ),
      body: _paymentSuccess
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: 'ticketId:$_ticketId',
              version: QrVersions.auto,
              size: 220,
            ),
            const SizedBox(height: 20),
            Text("Ticket ID: $_ticketId"),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Bus: ${bus['busNumber']} (${bus['from']} ➝ ${bus['to']})",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              if (_userPhone == "unknown") ...[
                TextFormField(
                  controller: _phoneController,
                  decoration:
                  const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
              ],

              Row(
                children: [
                  const Text("No. of Tickets: "),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _ticketCount,
                    items: List.generate(5, (index) => index + 1)
                        .map((num) => DropdownMenuItem(
                      value: num,
                      child: Text(num.toString()),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _ticketCount = val!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _startPayment();
                  }
                },
                icon: const Icon(Icons.payment),
                label: Text("Pay ₹$totalAmount"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
