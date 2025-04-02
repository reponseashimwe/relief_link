import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../components/navigation/custom_bottom_nav.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({Key? key}) : super(key: key);

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLocationSaving = false;
  LatLng _selectedLocation = const LatLng(0, 0);
  String _selectedLocationName = '';
  Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  List<String>? _searchResults;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = await authProvider.getUserData();
      
      if (userData != null && userData['location'] != null) {
        final location = userData['location'];
        if (location['latitude'] != null && location['longitude'] != null) {
          final double lat = location['latitude'];
          final double lng = location['longitude'];
          
          // If we have a saved location, use it
          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _selectedLocationName = location['locationName'] ?? 'Selected location';
          });
          
          // Update the marker and animate the camera to the saved location
          _updateMarker();
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 15),
          );
        }
      }
    } catch (e) {
      print('Error loading user location: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _selectedLocationName = 'Current location';
        _isLoading = false;
      });
      
      _updateMarker();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          infoWindow: InfoWindow(title: _selectedLocationName),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = null;
    });

    // Since we don't have direct access to geocoding, we'll use a simpler approach
    // just for searching and setting the location name

    try {
      // This is a simplified approach - in a real app without geocoding,
      // you might need to use a different API or service
      setState(() {
        _selectedLocationName = query;
        _updateMarker();
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: ${e.toString()}')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    setState(() {
      _isLocationSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Save location to user profile in Firestore
      await authProvider.updateUserData({
        'location': {
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
          'locationName': _selectedLocationName,
        },
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLocationSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose your location',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Let's find your unforgettable event.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Choose a location below to get started.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _isSearching 
                          ? const Padding(
                              padding: EdgeInsets.all(14.0),
                              child: SizedBox(
                                width: 20, 
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Set Location button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show full screen map
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(_selectedLocation, 16),
                      );
                    },
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF1B4332),
                      size: 20,
                    ),
                    label: const Text(
                      'Set Location on Map',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // Current Location section
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Map preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        // Map container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation,
                              zoom: 15,
                            ),
                            markers: _markers,
                            onTap: (position) {
                              setState(() {
                                _selectedLocation = position;
                                _selectedLocationName = 'Selected location';
                              });
                              _updateMarker();
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                        
                        // Location name bubble
                        if (_selectedLocationName.isNotEmpty)
                          Positioned(
                            top: 80,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4332),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedLocationName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Current location marker
                        Positioned(
                          top: 120,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Use Current Location button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLocationSaving ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLocationSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index != 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
} 