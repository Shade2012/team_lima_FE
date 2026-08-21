import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/auth/data/models/user_model.dart';
import 'package:veloce/features/gate/data/models/gate_model.dart';
import 'package:veloce/features/gate/data/repositories/gate_repository.dart';
import 'package:veloce/features/gate/presentation/pages/organizer/register_gate_operator_page.dart';

class GateOperatorsPage extends StatefulWidget {
  final String gateId;
  final String gateName;
  final String eventId;
  final String eventName;

  const GateOperatorsPage({
    super.key,
    required this.gateId,
    required this.gateName,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<GateOperatorsPage> createState() => _GateOperatorsPageState();
}

class _GateOperatorsPageState extends State<GateOperatorsPage> {
  final _repository = GateRepository();
  bool _isLoading = true;
  String? _error;
  Gate? _gate;

  @override
  void initState() {
    super.initState();
    _loadGate();
  }

  Future<void> _loadGate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final gate = await _repository.getGateById(widget.gateId);
      if (mounted) {
        setState(() {
          _gate = gate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          widget.gateName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGate,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRegisterOperator(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add),
        label: Text('Register Operator', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_gate == null) {
      return _buildEmptyState();
    }

    final operators = _gate!.operators;

    if (operators.isEmpty) {
      return _buildEmptyState();
    }

    return _buildOperatorsList(operators);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Retry', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Operator Yet',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This gate does not yet have an assigned operator.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorsList(List<UserModel> operators) {
    return RefreshIndicator(
      onRefresh: _loadGate,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.door_front_door,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gateName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${operators.length} operator assigned',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'List of Operators',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...operators.map((operator) => _buildOperatorCard(operator)),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(UserModel operator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operator.username,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  operator.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Active',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRegisterOperator() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterGateOperatorPage(
          eventId: widget.eventId,
          eventName: widget.eventName,
          gateId: widget.gateId,
          gateName: widget.gateName,
        ),
      ),
    );
    if (mounted) {
      _loadGate();
    }
  }
}
