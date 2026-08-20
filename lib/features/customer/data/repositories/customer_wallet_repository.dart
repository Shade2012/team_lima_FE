import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_wallet_model.dart';

class CustomerWalletRepository {
  final DioClient _dioClient = DioClient();

  /// GET /wallet
  Future<CustomerWalletModel> getWallet() async {
    try {
      final response = await _dioClient.dio.get('/wallet');
      final data = response.data['data'];
      return CustomerWalletModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load wallet balance'),
      );
    }
  }

  /// POST /wallet/topup
  Future<CustomerWalletModel> topUpWallet(int amount) async {
    try {
      final response = await _dioClient.dio.post(
        '/wallet/topup',
        data: {'amount': amount},
      );
      final data = response.data['data'];
      return CustomerWalletModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to top up wallet'),
      );
    }
  }

  /// GET /wallet/transactions
  Future<List<CustomerWalletTransactionModel>> getWalletTransactions() async {
    try {
      final response = await _dioClient.dio.get('/wallet/transactions');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map(
              (e) => CustomerWalletTransactionModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load transactions'),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) return message.map((m) => m.toString()).join('\n');
      }
    }
    return e.message ?? fallback;
  }
}
