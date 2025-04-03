import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_tab.dart'; // Import the PostTab

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the title bold
          ),
        ),
        centerTitle: true, // Ensure the title is centered
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Post'),
            Tab(text: 'Volunteer'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicatorColor: const Color(0xFF1A3C34),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicator: BoxDecoration(
            color: const Color(0xFF1A3C34),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PostTab(), // Use the imported PostTab
        ],
      ),
    );
  }
}

