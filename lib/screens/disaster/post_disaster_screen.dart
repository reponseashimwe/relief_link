import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart' as app_provider;
import '../../models/disaster.dart';
import '../../constants/app_constants.dart';

class PostDisasterScreen extends StatefulWidget {
  const PostDisasterScreen({super.key});

  @override
  State<PostDisasterScreen> createState() => _PostDisasterScreenState();
}

class _PostDisasterScreenState extends State<PostDisasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DisasterCategory _selectedCategory = DisasterCategory.earthquake;
  List<dynamic> _selectedImages = [];
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
    }
  }

  Future<void> _submitDisaster() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<app_provider.AuthProvider>(context, listen: false);
      final user = authProvider.currentUser!;

      // Upload images to Firebase Storage
      final List<String> imageUrls = await StorageService.uploadMultipleFiles(_selectedImages);

      // Create disaster document
      final disaster = Disaster(
        id: '', // Will be set by Firestore
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        images: imageUrls,
        coordinates: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        category: _selectedCategory.name,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection(Collections.disasters)
          .add(disaster.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disaster reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview(dynamic image, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          if (kIsWeb)
            FutureBuilder<Uint8List>(
              future: (image as XFile).readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  );
                }
                return const SizedBox(
                  height: 100,
                  width: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            )
          else
            Image.file(
              image as File,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Disaster'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DisasterCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: DisasterCategory.values
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a location' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedLocation != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: _selectedLocation!,
                            ),
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) => _buildImagePreview(_selectedImages[index], index),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Add Images'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitDisaster,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit Report'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 