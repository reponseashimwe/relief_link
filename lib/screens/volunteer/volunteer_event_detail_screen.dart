import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_event.dart';
import '../community/form_join_screen.dart';

class VolunteerEventDetailScreen extends StatelessWidget {
  final VolunteerEvent event;

  const VolunteerEventDetailScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              // Share event
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Date and location
                  _buildInfoRow(
                    Icons.calendar_today,
                    dateFormat.format(event.date),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    timeFormat.format(event.date),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    event.location,
                  ),
                  const SizedBox(height: 24),
                  
                  // Volunteer count
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Volunteers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.currentVolunteers} of ${event.targetVolunteers} spots filled',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        CircularProgressIndicator(
                          value: event.currentVolunteers / event.targetVolunteers,
                          backgroundColor: Colors.grey[300],
                          color: const Color(0xFF4CAF50),
                          strokeWidth: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Registered Volunteers
                  const Text(
                    'Registered Volunteers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildRegisteredVolunteers(context),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'About This Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Photos
                  if (event.photoUrls.isNotEmpty) ...[
                    const Text(
                      'Event Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.photoUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(event.photoUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: event.currentVolunteers < event.targetVolunteers
                ? () {
                    // Register as volunteer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormJoinScreen(event: event),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
            ),
            child: Text(
              event.currentVolunteers < event.targetVolunteers
                  ? 'Register as Volunteer'
                  : 'Event is Full',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRegisteredVolunteers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('volunteer_registrations')
        .where('eventId', isEqualTo: event.id)
        .orderBy('registeredAt', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No volunteers have registered for this event yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        
        // Show volunteer list
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${snapshot.data!.docs.length} volunteers',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all volunteers
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final volunteer = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            volunteer['fullName']?.substring(0, 1).toUpperCase() ?? 'V',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          volunteer['fullName']?.split(' ')[0] ?? 'Volunteer',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
} 