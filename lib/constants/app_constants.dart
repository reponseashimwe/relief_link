import 'package:flutter/material.dart';

// Disaster Categories
enum DisasterCategory {
  earthquake('Earthquake'),
  flood('Flood'),
  fire('Fire'),
  hurricane('Hurricane'),
  tornado('Tornado'),
  landslide('Landslide'),
  tsunami('Tsunami'),
  drought('Drought'),
  other('Other');

  final String label;
  const DisasterCategory(this.label);

  String get name => label;
}

// Emergency Service Types
enum EmergencyServiceType {
  medical('Medical'),
  police('Police'),
  fire('Fire'),
  rescue('Rescue'),
  hazmat('Hazmat'),
  social('Social Services');

  final String label;
  const EmergencyServiceType(this.label);

  String get name => label;
}

// User Roles
enum UserRole {
  user('User'),
  admin('Admin'),
  emergencyService('Emergency Service');

  final String label;
  const UserRole(this.label);

  String get name => label;
}

// App Colors
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC04);
  static const Color success = Color(0xFF34A853);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF202124);
  static const Color onSurface = Color(0xFF202124);
}

// API Keys and Endpoints
class ApiConfig {
  static const String cloudinaryCloudName = 'dxeepn9qa';
  static const String cloudinaryApiKey = '396133459978945';
  static const String cloudinaryApiSecret = 'lij0YD3ThmYd_dPkBwpfSAplWxk';
  static const String cloudinaryUploadPreset = 'ml_default';
}

// Collection Names
class Collections {
  static const String users = 'users';
  static const String disasters = 'disasters';
  static const String emergencyServices = 'emergency_services';
  static const String chats = 'chats';
  static const String messages = 'messages';
}

// Storage Keys
class StorageKeys {
  static const String themeMode = 'theme_mode';
  static const String userRole = 'user_role';
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
}

class Location {
  final String id;
  final String name;
  final String country;

  const Location({
    required this.id,
    required this.name,
    required this.country,
  });

  static const List<Location> locations = [
    Location(
      id: 'san-diego',
      name: 'San Diego',
      country: 'United States',
    ),
    Location(
      id: 'tokyo',
      name: 'Tokyo',
      country: 'Japan',
    ),
    Location(
      id: 'sydney',
      name: 'Sydney',
      country: 'Australia',
    ),
    Location(
      id: 'london',
      name: 'London',
      country: 'United Kingdom',
    ),
    Location(
      id: 'nairobi',
      name: 'Nairobi',
      country: 'Kenya',
    ),
  ];
}

class EmergencyService {
  final String id;
  final String name;
  final String iconAsset;
  final String phoneNumber;
  final String role;
  final String description;

  const EmergencyService({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.phoneNumber,
    required this.role,
    required this.description,
  });

  static const List<EmergencyService> services = [
    EmergencyService(
      id: 'ambulance',
      name: 'Ambulance',
      iconAsset: 'assets/images/ambulance_icon.png',
      phoneNumber: '911',
      role: 'ambulance',
      description: 'Emergency Medical Services',
    ),
    EmergencyService(
      id: 'hospital',
      name: 'Hospital',
      iconAsset: 'assets/images/hospital_icon.png',
      phoneNumber: '911',
      role: 'hospital',
      description: 'Medical Facility',
    ),
    EmergencyService(
      id: 'police',
      name: 'Police',
      iconAsset: 'assets/images/police_icon.png',
      phoneNumber: '911',
      role: 'police',
      description: 'Law Enforcement',
    ),
    EmergencyService(
      id: 'firefighter',
      name: 'Firefighter',
      iconAsset: 'assets/images/firefighter_icon.png',
      phoneNumber: '911',
      role: 'firefighter',
      description: 'Fire Department',
    ),
    EmergencyService(
      id: 'electricity',
      name: 'Electricity',
      iconAsset: 'assets/images/electricity_icon.png',
      phoneNumber: '800-4357',
      role: 'electricity',
      description: 'Power Emergency Services',
    ),
    EmergencyService(
      id: 'hazmat',
      name: 'HazMat Teams',
      iconAsset: 'assets/images/hazmat_icon.png',
      phoneNumber: '800-424-8802',
      role: 'hazmat',
      description: 'Hazardous Materials Response',
    ),
  ];
} 