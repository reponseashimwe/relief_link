import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_provider;
import '../../constants/app_constants.dart';
import '../../components/navigation/custom_app_bar.dart';
import 'chat_screen.dart';

class ServiceDashboard extends StatefulWidget {
  const ServiceDashboard({super.key});

  @override
  State<ServiceDashboard> createState() => _ServiceDashboardState();
}

class _ServiceDashboardState extends State<ServiceDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    
    if (!authProvider.isEmergencyService && !authProvider.isAdmin) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Service Dashboard'),
        body: const Center(
          child: Text('You do not have access to this page'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active Chats'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(false),
          _buildChatList(true),
        ],
      ),
    );
  }

  Widget _buildChatList(bool resolved) {
    final serviceRole = Provider.of<app_provider.AuthProvider>(context).userRole;
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('serviceRole', isEqualTo: serviceRole)
          .where('resolved', isEqualTo: resolved)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              resolved 
                ? 'No resolved chats'
                : 'No active chats',
            ),
          );
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chat = snapshot.data!.docs[index];
            final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
            final formattedTime = lastMessageTime != null
                ? '${lastMessageTime.toDate().hour}:${lastMessageTime.toDate().minute.toString().padLeft(2, '0')}'
                : '';
            
            return _ChatItem(
              userName: chat['userName'] ?? 'Unknown',
              lastMessage: chat['lastMessage'] ?? '',
              time: formattedTime,
              onTap: () {
                // Find service from the list
                final service = EmergencyService.services.firstWhere(
                  (s) => s.id == chat['serviceId'],
                  orElse: () => EmergencyService.services.first,
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      service: service,
                    ),
                  ),
                );
              },
              markAsResolved: !resolved 
                ? () async {
                    await _firestore.collection('chats').doc(chat.id).update({
                      'resolved': true,
                      'resolvedAt': FieldValue.serverTimestamp(),
                      'resolvedBy': _auth.currentUser!.uid,
                    });
                  }
                : null,
            );
          },
        );
      },
    );
  }
}

class _ChatItem extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final String time;
  final VoidCallback onTap;
  final VoidCallback? markAsResolved;

  const _ChatItem({
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.onTap,
    this.markAsResolved,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        userName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (markAsResolved != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: markAsResolved,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Resolve',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 