class DisasterCategory {
  final String id;
  final String name;
  final String imageUrl;

  const DisasterCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  static const List<DisasterCategory> categories = [
    DisasterCategory(
      id: 'earthquake',
      name: 'Earthquake',
      imageUrl: 'assets/images/earthquake.jpg',
    ),
    DisasterCategory(
      id: 'flood',
      name: 'Flood',
      imageUrl: 'assets/images/flood.jpg',
    ),
    DisasterCategory(
      id: 'wildfire',
      name: 'Wildfire',
      imageUrl: 'assets/images/wildfire.jpg',
    ),
    DisasterCategory(
      id: 'hurricane',
      name: 'Hurricane',
      imageUrl: 'assets/images/hurricane.jpg',
    ),
    DisasterCategory(
      id: 'drought',
      name: 'Drought',
      imageUrl: 'assets/images/drought.jpg',
    ),
  ];
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

class UserRole {
  static const String user = 'user';
  static const String admin = 'admin';
  static const String ambulance = 'ambulance';
  static const String hospital = 'hospital';
  static const String police = 'police';
  static const String firefighter = 'firefighter';
  static const String electricity = 'electricity';
  static const String hazmat = 'hazmat';
} 