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

class _ServiceDashboardState extends State<ServiceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add this field to store the service ID
  String? _serviceId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch and store service ID early
    _fetchServiceId();
  }

  // Add this method to fetch service ID
  Future<void> _fetchServiceId() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _serviceId = doc.data()?['serviceId'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching service ID: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final user = authProvider.currentUser;
    if (user == null) return const Center(child: Text('User not logged in'));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
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
          _buildAlternativeChatList(false),
          _buildAlternativeChatList(true),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildChatList(bool resolved) {
    if (_serviceId == null) {
      return const Center(child: Text('Service ID not available'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('serviceId', isEqualTo: _serviceId)
          .where('resolved', isEqualTo: resolved)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              resolved ? 'No resolved chats' : 'No active chats',
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
                      chatId: chat.id,
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

  Widget _buildAlternativeChatList(bool resolved) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('chats').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        // Filter the chats manually
        final allChats = snapshot.data!.docs;
        final filteredChats = allChats.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final chatServiceId = data['serviceId'];
          final chatResolved = data['resolved'] ?? false;

          return chatServiceId == _serviceId && chatResolved == resolved;
        }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Text(resolved ? 'No resolved chats' : 'No active chats'),
          );
        }

        // Sort by lastMessageTime
        filteredChats.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['lastMessageTime'] as Timestamp?;
          final bTime = bData['lastMessageTime'] as Timestamp?;

          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime); // Descending order
        });

        return ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chatDoc = filteredChats[index];
            final chat = chatDoc.data() as Map<String, dynamic>;

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
                      chatId: chatDoc.id,
                    ),
                  ),
                );
              },
              markAsResolved: !resolved
                  ? () async {
                      await _firestore
                          .collection('chats')
                          .doc(chatDoc.id)
                          .update({
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

  // ignore: unused_element
  Future<void> _fixChatData() async {
    try {
      final chats = await _firestore.collection('chats').get();

      for (var doc in chats.docs) {
        final data = doc.data();

        // Check if resolved is actually a boolean
        if (data['resolved'] != null && data['resolved'] is! bool) {
          await doc.reference.update({'resolved': false});
        }

        // Check if lastMessageTime is null
        if (data['lastMessageTime'] == null) {
          await doc.reference
              .update({'lastMessageTime': FieldValue.serverTimestamp()});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat data verification complete')),
      );
    } catch (e) {
      debugPrint('Error fixing chat data: $e');
    }
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
