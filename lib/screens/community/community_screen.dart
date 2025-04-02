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
          VolunteerTab(),
        ],
      ),
    );
  }
}

class VolunteerTab extends StatefulWidget {
  const VolunteerTab({super.key});

  @override
  _VolunteerTabState createState() => _VolunteerTabState();
}

class _VolunteerTabState extends State<VolunteerTab> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(selectedDate?.toString().split(' ')[0] ?? "December 2024"),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => selectedDate = picked);
          },
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('volunteer_opportunities')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final opportunities = snapshot.data!.docs;
              return ListView.builder(
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  var opp = opportunities[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        opp['media'][0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(opp['title']),
                      subtitle: Text(opp['location']['name']),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3C34)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VolunteerDetailPage(oppId: opportunities[index].id),
                            ),
                          );
                        },
                        child: const Text("See Detail"),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class VolunteerDetailPage extends StatelessWidget {
  final String oppId;

  const VolunteerDetailPage({super.key, required this.oppId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
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
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('volunteer_opportunities')
            .doc(oppId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var opp = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            child: Column(
              children: [
                Image.network(
                  opp['media'][0],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                ListTile(
                  title: Text(opp['title']),
                  subtitle: Text(opp['date']),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    opp['description'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: opp['media'].length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.network(
                          opp['media'][index],
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: opp['currentVolunteers'] / opp['targetVolunteers'],
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xFF1A3C34)),
                  ),
                ),
                Text("${opp['currentVolunteers']}/${opp['targetVolunteers']} Volunteers"),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C34),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('volunteer_registrations')
                          .add({
                        'userId': 'user456',
                        'userName': 'Amina',
                        'opportunityId': oppId,
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'Pending',
                        'skills': ['First Aid'],
                        'availability': {
                          'start': '2025-04-15T08:00:00Z',
                          'end': '2025-04-15T17:00:00Z',
                        },
                      });
                      await FirebaseFirestore.instance
                          .collection('volunteer_opportunities')
                          .doc(oppId)
                          .update({
                        'currentVolunteers': FieldValue.increment(1),
                      });
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationConfirmationPage(),
                        ),
                      );
                    },
                    child: const Text("Join Volunteer"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RegistrationConfirmationPage extends StatelessWidget {
  const RegistrationConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.thumb_up, size: 100, color: Color(0xFF1A3C34)),
            const Text(
              "Your registration has been submitted",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Thank you for registering, please wait for our email for event details",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C34),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}