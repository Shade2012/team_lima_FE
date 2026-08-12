import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Default local mock server base URL.
  /// On Android emulator, localhost is 10.0.2.2.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  // Feature: Account & Authentication (/users)
  static const String register = '/users/register';
  static const String login = '/users/login';
  static const String profile = '/users/profile';
  static const String logout = '/users/logout';
  static const String deleteUser = '/users';

  // Feature: Event Management (/events)
  static const String events = '/events';
  static const String myOrganizerEvents = '/events/organizer/me';
  static String eventDetail(String id) => '/events/$id';

  // Feature: Ticket Category (/ticket-categories)
  static const String ticketCategories = '/ticket-categories';
  static String categoriesByEvent(String eventId) => '/ticket-categories/event/$eventId';
  static String categoryDetail(String id) => '/ticket-categories/$id';

  // Feature: Seat Management (/seats)
  static const String bulkSeats = '/seats/bulk';
  static String seatsByCategory(String categoryId) => '/seats/category/$categoryId';

  // Feature: Gate Management (/gates)
  static const String gates = '/gates';
  static String gatesByEvent(String eventId) => '/gates/event/$eventId';
  static String gateDetail(String id) => '/gates/$id';
}
