import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../constants/colors.dart';
import '../../models/disaster.dart';
import '../../constants/app_constants.dart';
import '../../widgets/map_container.dart';
import '../disaster/post_disaster_screen.dart';
import '../disaster/disaster_details_screen.dart';
import '../disaster/disaster_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase data
  List<Disaster> _disasters = [];
  bool _isLoading = true;
  String _selectedTimeFilter = 'This week';
  Disaster? _selectedDisaster;
  
  // Default to Kigali coordinates
  final LatLng _kigaliLocation = const LatLng(-1.9403, 30.0598);
  
  @override
  void initState() {
    super.initState();
    _fetchDisasters();
  }
  
  Future<void> _fetchDisasters() async {
    setState(() => _isLoading = true);
    
    try {
      // Get disasters from Firebase
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(Collections.disasters)
          .orderBy('createdAt', descending: true)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        List<Disaster> fetchedDisasters = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          fetchedDisasters.add(Disaster.fromMap(data, doc.id));
        }
        
        setState(() {
          _disasters = fetchedDisasters;
          // Set the first disaster as selected by default
          if (_disasters.isNotEmpty) {
            _selectedDisaster = _disasters[0];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading disasters: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Filter disasters based on selected time filter
  List<Disaster> get filteredDisasters {
    if (_disasters.isEmpty) return [];
    
    final now = DateTime.now();
    
    switch (_selectedTimeFilter) {
      case 'This week':
        // This week's disasters (last 7 days)
        final weekAgo = now.subtract(const Duration(days: 7));
        return _disasters.where((d) => d.createdAt.isAfter(weekAgo)).toList();
      case 'This month':
        // This month's disasters (last 30 days)
        final monthAgo = now.subtract(const Duration(days: 30));
        return _disasters.where((d) => d.createdAt.isAfter(monthAgo)).toList();
      default:
        return _disasters;
    }
  }
  
  // Get the map location - either the selected disaster or default to Kigali
  LatLng get _mapLocation {
    if (_selectedDisaster != null) {
      return LatLng(
        _selectedDisaster!.coordinates.latitude, 
        _selectedDisaster!.coordinates.longitude
      );
    }
    return _kigaliLocation;
  }
  
  // Format the time difference for display
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  // Format the date for display
  String _formatDate(DateTime date) {
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with profile and actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: user?.photoURL != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: user!.photoURL!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Hi Welcome ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    '👋',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                user?.displayName ?? 'Rep App',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[100],
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[100],
                            ),
                            child: const Icon(
                              Icons.notifications_none_outlined,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Donation Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to donation page
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEDF6E5), Color(0xFFF5EAD7)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Together for Rwanda,',
                                        style: TextStyle(
                                          color: Color(0xFF1B4332),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Stronger in Relief',
                                        style: TextStyle(
                                          color: Color(0xFF1B4332),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[100],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'See Donations',
                                          style: TextStyle(
                                            color: Color(0xFF1B4332),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  child: Image.asset(
                                    'assets/images/donation.jpg',
                                    fit: BoxFit.cover,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Disaster Information Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Disaster Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DisasterListScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildTimeFilterButton('This week', Icons.notifications_none_outlined),
                          const SizedBox(width: 12),
                          _buildTimeFilterButton('This month', Icons.history),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Show no disasters message if none are available
                    if (filteredDisasters.isEmpty && !_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No disasters found for the selected time period',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Map with Disaster Location
                    if (filteredDisasters.isNotEmpty || _selectedDisaster != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: MapContainer(
                              position: _mapLocation,
                              locationName: _selectedDisaster?.location ?? "Kigali, Rwanda",
                              mapType: MapType.hybrid,
                              height: 200,
                              zoomEnabled: true,
                              title: _selectedDisaster?.title,
                              snippet: _selectedDisaster?.location,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Current Disaster Details Card
                    if (_selectedDisaster != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDisaster!.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(_selectedDisaster!.createdAt),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getTimeAgo(_selectedDisaster!.createdAt),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Created by: ${_selectedDisaster!.userName}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DisasterDetailsScreen(disaster: _selectedDisaster!),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B4332),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('View Details'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Live News Section - Shows all disasters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'More Disasters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DisasterListScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Still Disasters Cards - Horizontal scroll
                    if (_disasters.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _disasters.length,
                          itemBuilder: (context, index) {
                            final disaster = _disasters[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDisaster = disaster;
                                });
                                
                                // Navigate to disaster details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DisasterDetailsScreen(disaster: disaster),
                                  ),
                                );
                              },
                              child: Container(
                                width: 250,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    // News image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: disaster.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: disaster.images[0],
                                              width: 250,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/images/earthquake.png',
                                              width: 250,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    // Overlay gradient
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            disaster.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(disaster.category),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  disaster.category.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  disaster.location,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PostDisasterScreen(),
              ),
            ).then((_) => _fetchDisasters()); // Refresh data when returning
          },
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  // Build markers for the map based on filtered disasters
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Add markers for filtered disasters
    for (var disaster in filteredDisasters) {
      markers.add(
        Marker(
          markerId: MarkerId(disaster.id),
          position: LatLng(
            disaster.coordinates.latitude,
            disaster.coordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: disaster.title,
            snippet: disaster.location,
          ),
          onTap: () {
            setState(() {
              _selectedDisaster = disaster;
            });
          },
        ),
      );
    }
    
    // If no markers but we have a selected disaster, show that
    if (markers.isEmpty && _selectedDisaster != null) {
      markers.add(
        Marker(
          markerId: MarkerId(_selectedDisaster!.id),
          position: LatLng(
            _selectedDisaster!.coordinates.latitude,
            _selectedDisaster!.coordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: _selectedDisaster!.title,
            snippet: _selectedDisaster!.location,
          ),
        ),
      );
    }
    
    // If still no markers, add one for Kigali
    if (markers.isEmpty) {
      markers.add(
        const Marker(
          markerId: MarkerId('kigali'),
          position: LatLng(-1.9403, 30.0598),
          infoWindow: InfoWindow(
            title: 'Kigali, Rwanda',
            snippet: 'Default location',
          ),
        ),
      );
    }
    
    return markers;
  }
  
  // Get color based on disaster category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'earthquake':
        return Colors.orange;
      case 'flood':
        return Colors.blue;
      case 'fire':
        return Colors.red;
      case 'tornado':
        return Colors.purple;
      case 'landslide':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildTimeFilterButton(String title, IconData iconData) {
    final bool isSelected = _selectedTimeFilter == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4332) : Colors.grey[200],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                iconData,
                color: isSelected ? Colors.white : Colors.black54,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
