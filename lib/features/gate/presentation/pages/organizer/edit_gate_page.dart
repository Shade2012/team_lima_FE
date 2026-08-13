import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/core/widgets/custom_text_field.dart';
import 'package:team_five_fe/features/gate/data/models/update_gate_request.dart';
import 'package:team_five_fe/features/gate/presentation/providers/gate_provider.dart';

class EditGatePage extends ConsumerStatefulWidget {
  final String gateId;
  final String gateName;
  final String eventId;

  const EditGatePage({
    super.key,
    required this.gateId,
    required this.gateName,
    required this.eventId,
  });

  @override
  ConsumerState<EditGatePage> createState() => _EditGatePageState();
}

class _EditGatePageState extends ConsumerState<EditGatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gateName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gatesState = ref.watch(gatesProvider);

    ref.listen<GatesState>(gatesProvider, (prev, next) {
      if (prev?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gate updated successfully!',
              style: AppTextStyles.snackbar,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          'Edit Gate',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gate Name Field
              Text(
                'Gate Name',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: 'e.g., Gate Utama Utara',
                prefixIcon: Icons.door_front_door_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gate name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Error Message
              if (gatesState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gatesState.error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: gatesState.isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: gatesState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Save Changes', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final request = UpdateGateRequest(name: _nameController.text.trim());
      await ref.read(gatesProvider.notifier).updateGate(widget.gateId, request);
    }
  }
}
