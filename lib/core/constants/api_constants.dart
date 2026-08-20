import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const bool isPhysicalDevice = true;
  static const String physicalDeviceIp = 'http://10.127.76.48:3000';

  /// Default local mock server base URL.
  /// On Android emulator, localhost is 10.0.2.2.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) {
      if (isPhysicalDevice) return physicalDeviceIp;
      return 'http://10.0.2.2:3000';
    }
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
  static String eventStatistics(String id) => '/events/$id/statistics';

  // Feature: Ticket Category (/ticket-categories)
  static const String ticketCategories = '/ticket-categories';
  static String categoriesByEvent(String eventId) =>
      '/ticket-categories/event/$eventId';
  static String categoryDetail(String id) => '/ticket-categories/$id';

  // Feature: Seat Management (/seats)
  static const String bulkSeats = '/seats/bulk';
  static String seatsByCategory(String categoryId) =>
      '/seats/category/$categoryId';
  static String deleteSeatsByCategory(String categoryId) =>
      '/seats/category/$categoryId';

  // Feature: Gate Management (/gates)
  static const String gates = '/gates';
  static String gatesByEvent(String eventId) => '/gates/event/$eventId';
  static String gateDetail(String id) => '/gates/$id';
  static const String assignedGate = '/gates/operator/assigned';

  // Feature: Gate Operator Registration (/users/register/gate-operator)
  static const String registerGateOperator = '/users/register/gate-operator';

  // Feature: Admission Scans (/scans)
  static const String scans = '/scans';

  // Feature: Refund Management (/refunds)
  static const String refunds = '/refunds';
  static String refundApprove(String id) => '/refunds/$id/approve';
  static String refundReject(String id) => '/refunds/$id/reject';

  // Feature: SSE (Server-Sent Events)
  static String sseSeats(String eventId) => '/sse/events/$eventId/seats';
  static String sseDashboard(String eventId) =>
      '/sse/events/$eventId/dashboard';
}
