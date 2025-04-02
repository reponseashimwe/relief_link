import 'package:flutter/material.dart';
import '../models/volunteer_event.dart';
import '../services/volunteer_service.dart';

class VolunteerProvider with ChangeNotifier {
  final VolunteerService _volunteerService = VolunteerService();
  List<VolunteerEvent> _events = [];
  List<VolunteerEvent> _filteredEvents = [];
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _error;

  List<VolunteerEvent> get events => _filteredEvents.isEmpty ? _events : _filteredEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> seedSampleEvents() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _volunteerService.seedSampleEvents();
      await loadVolunteerEvents();
    } catch (e) {
      _error = 'Failed to seed sample events: $e';
      notifyListeners();
    }
  }

  void filterEventsByDate(DateTime date) {
    _selectedDate = date;
    _filteredEvents = _events.where((event) {
      return event.date.year == date.year &&
             event.date.month == date.month &&
             event.date.day == date.day;
    }).toList();

    // If no events found for the selected date, show all events
    if (_filteredEvents.isEmpty) {
      _filteredEvents = _events;
    }
    
    notifyListeners();
  }

  Future<void> loadVolunteerEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _events = await _volunteerService.getVolunteerEvents();
      
      // If we have a selected date, filter the events
      if (_selectedDate != null) {
        filterEventsByDate(_selectedDate!);
      } else {
        _filteredEvents = _events;
      }
    } catch (e) {
      _error = 'Failed to load volunteer events: $e';
      _filteredEvents = [];
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinEvent({
    required String eventId,
    required String userId,
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final success = await _volunteerService.joinVolunteerEvent(
        eventId: eventId,
        userId: userId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      );

      if (success) {
        await loadVolunteerEvents();
      }

      return success;
    } catch (e) {
      _error = 'Failed to join event: $e';
      notifyListeners();
      return false;
    }
  }
} 