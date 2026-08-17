import '../../../auth/data/models/user_model.dart';

class Gate {
  final String id;
  final String name;
  final String? eventId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AdmissionScan> scans;
  final List<UserModel> operators;

  Gate({
    required this.id,
    required this.name,
    this.eventId,
    this.createdAt,
    this.updatedAt,
    this.scans = const [],
    this.operators = const [],
  });

  int get scannedCount => scans.length;

  factory Gate.fromJson(Map<String, dynamic> json) {
    final scansData = json['scans'];
    final operatorsData = json['operators'];
    return Gate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      eventId: json['eventId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      scans: scansData is List
          ? scansData.map((e) => AdmissionScan.fromJson(e)).toList()
          : [],
      operators: operatorsData is List
          ? operatorsData
                .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eventId': eventId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class AdmissionScan {
  final String id;
  final DateTime scannedAt;
  final String? ticketId;
  final String? gateOperatorId;
  final String? gateId;

  AdmissionScan({
    required this.id,
    required this.scannedAt,
    this.ticketId,
    this.gateOperatorId,
    this.gateId,
  });

  factory AdmissionScan.fromJson(Map<String, dynamic> json) {
    return AdmissionScan(
      id: json['id']?.toString() ?? '',
      scannedAt:
          DateTime.tryParse(json['scannedAt'].toString()) ?? DateTime.now(),
      ticketId: json['ticketId']?.toString(),
      gateOperatorId: json['gateOperatorId']?.toString(),
      gateId: json['gateId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scannedAt': scannedAt.toIso8601String(),
      'ticketId': ticketId,
      'gateOperatorId': gateOperatorId,
      'gateId': gateId,
    };
  }
}
