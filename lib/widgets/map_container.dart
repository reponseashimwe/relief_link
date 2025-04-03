 import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapContainer extends StatefulWidget {
  final LatLng position;
  final double height;
  final String? title;
  final String? snippet;
  final MapType mapType;
  final bool zoomEnabled;
  final String locationName;

  const MapContainer({
    Key? key,
    required this.position,
    this.height = 200,
    this.title,
    this.snippet,
    this.mapType = MapType.normal,
    this.zoomEnabled = false,
    required this.locationName,
  }) : super(key: key);

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  bool _isMapReady = false;
  bool _mapLoadError = false;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_mapLoadError)
            _buildFallbackWidget()
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.position,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(widget.title ?? "location"),
                  position: widget.position,
                  infoWindow: InfoWindow(
                    title: widget.title,
                    snippet: widget.snippet,
                  ),
                ),
              },
              mapType: widget.mapType,
              zoomControlsEnabled: widget.zoomEnabled,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (mounted) {
                  setState(() {
                    _isMapReady = true;
                  });
                }
              },
            ),
          // Show loading indicator while map is loading
          if (!_isMapReady && !_mapLoadError)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Position indicator for location name
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    widget.locationName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              widget.locationName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${widget.position.latitude}, ${widget.position.longitude}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper method to convert GeoPoint to LatLng
LatLng geoPointToLatLng(GeoPoint geoPoint) {
  return LatLng(geoPoint.latitude, geoPoint.longitude);
} 