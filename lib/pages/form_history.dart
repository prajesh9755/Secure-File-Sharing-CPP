import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Request History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cyber_requests')
                .where('sender_email', isEqualTo: userEmail)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return _buildNoHistoryFound();

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final cafeName = data['selected_cafe'] ?? "General";
                  final status = data['status'] ?? 'Pending';
                  final scholarship = data['scholarship_type'] ?? "No Details";

                  return _buildHistoryCard(scholarship, cafeName, status);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(String scholarship, String cafe, String status) {
    // Get gradient based on status
    final List<Color> statusGradient = _getStatusGradient(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusGradient.first.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIconData(status),
              color: statusGradient.first,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scholarship,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      cafe,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- NEW GRADIENT STATUS CHIP ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: statusGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: statusGradient.last.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Status Gradients (Matching Homepage Style)
  List<Color> _getStatusGradient(String status) {
    if (status == 'Completed') {
      return [const Color(0xFF11998e), const Color(0xFF38ef7d)]; // Premium Green
    } else if (status == 'Processing') {
      return [const Color(0xFFf2994a), const Color(0xFFf2c94c)]; // Premium Orange/Gold
    } else {
      return [const Color(0xFFeb5757), const Color(0xFF000000).withOpacity(0.6)]; // Premium Red/Dark
    }
  }

  IconData _getStatusIconData(String status) {
    if (status == 'Completed') return Icons.check_circle_rounded;
    if (status == 'Processing') return Icons.sync_rounded;
    return Icons.pending_actions_rounded;
  }

  Widget _buildNoHistoryFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No history found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}