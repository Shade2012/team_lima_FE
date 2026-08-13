import 'package:dio/dio.dart';
import '../models/gate_model.dart';
import '../models/create_gate_request.dart';
import '../models/update_gate_request.dart';
import '../models/gate_operator_request.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/models/user_model.dart';

class GateRepository {
  final DioClient _dioClient = DioClient();

  /// GET /gates/event/:eventId
  Future<List<Gate>> getGatesByEvent(String eventId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.gatesByEvent(eventId),
      );
      final data = response.data['data'] as List;
      return data.map((e) => Gate.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch gates'),
      );
    }
  }

  /// POST /gates
  Future<Gate> createGate(CreateGateRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.gates,
        data: request.toJson(),
      );
      return Gate.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to create gate'),
      );
    }
  }

  /// PATCH /gates/:id
  Future<Gate> updateGate(String id, UpdateGateRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConstants.gateDetail(id),
        data: request.toJson(),
      );
      return Gate.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to update gate'),
      );
    }
  }

  /// DELETE /gates/:id
  Future<void> deleteGate(String id) async {
    try {
      await _dioClient.dio.delete(ApiConstants.gateDetail(id));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to delete gate'),
      );
    }
  }

  /// POST /users/register/gate-operator
  Future<List<UserModel>> registerGateOperator(
    GateOperatorRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.registerGateOperator,
        data: request.toJson(),
      );
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [UserModel.fromJson(data)];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          fallback: 'Failed to register gate operator',
        ),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) {
          return message.map((m) => m.toString()).join('\n');
        }
      }
    }
    return e.message ?? fallback;
  }
}
