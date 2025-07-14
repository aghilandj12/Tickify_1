import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import 'bus_info_page.dart';
import 'book_tickets_page.dart';
import 'view_tickets_page.dart';

class HomePage extends StatefulWidget {
  final String loggedInPhone;
  final String userName;
  final String userEmail;
  final String userDocId;

  const HomePage({
    super.key,
    required this.loggedInPhone,
    required this.userName,
    required this.userEmail,
    required this.userDocId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeMainButtons(
        userPhone: widget.loggedInPhone,
        userName: widget.userName,
      ),
      ProfilePage(
        phone: widget.loggedInPhone,
        name: widget.userName,
        email: widget.userEmail,
        docId: widget.userDocId,
      ),
      const NotificationPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tickify"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notify'),
        ],
      ),
    );
  }
}

class _HomeMainButtons extends StatelessWidget {
  final String userPhone;
  final String userName;

  const _HomeMainButtons({
    super.key,
    required this.userPhone,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Hi $userName 👋",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildHomeButton(
            context,
            icon: Icons.info_outline,
            label: "Bus Info",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusInfoPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildHomeButton(
            context,
            icon: Icons.add_road,
            label: "Book Tickets",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookTicketsPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildHomeButton(
            context,
            icon: Icons.receipt_long,
            label: "View Tickets",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewTicketsPage(phoneNumber: userPhone),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}
