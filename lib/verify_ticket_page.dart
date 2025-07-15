import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class VerifyTicketPage extends StatefulWidget {
  const VerifyTicketPage({super.key});

  @override
  State<VerifyTicketPage> createState() => _VerifyTicketPageState();
}

class _VerifyTicketPageState extends State<VerifyTicketPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) return;
      isProcessing = true;

      final ticketId = scanData.code?.replaceAll("ticketId:", "").trim();
      if (ticketId == null || ticketId.isEmpty) {
        _showSnackBar("Invalid QR Code");
        isProcessing = false;
        return;
      }

      final ticketSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('ticketId', isEqualTo: ticketId)
          .get();

      if (ticketSnapshot.docs.isEmpty) {
        _showSnackBar("Ticket not found");
        isProcessing = false;
        return;
      }

      final ticketDoc = ticketSnapshot.docs.first;
      final ticketData = ticketDoc.data();
      final status = ticketData['status'] ?? 'active';

      if (status == 'used') {
        _showSnackBar("Ticket already used");
        isProcessing = false;
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Mark Ticket as Used?"),
          content: Text("Bus: ${ticketData['busNumber']}\n"
              "From: ${ticketData['from']} ➝ ${ticketData['to']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                isProcessing = false;
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('tickets')
                    .doc(ticketDoc.id)
                    .update({'status': 'used'});

                Navigator.pop(context);
                _showSnackBar("Ticket marked as used");
                isProcessing = false;
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Ticket"),
        backgroundColor: Colors.orange,
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}
