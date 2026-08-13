import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/core/widgets/custom_text_field.dart';
import 'package:team_five_fe/features/event/data/models/create_event_request.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _refundPolicyController = TextEditingController();
  final _refundPercentageController = TextEditingController();

  bool _isSeated = false;
  DateTime? _salesStartTime;
  DateTime? _salesEndTime;
  DateTime? _eventDate;
  DateTime? _refundEndDate;

  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void dispose() {
    _nameController.dispose();
    _refundPolicyController.dispose();
    _refundPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createEventProvider);

    ref.listen<CreateEventState>(createEventProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event created successfully!',
              style: AppTextStyles.snackbar,
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(createEventProvider.notifier).reset();
        Navigator.pop(context);
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: AppTextStyles.snackbar),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event', style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(),
              const SizedBox(height: 16),
              _buildIsSeatedSwitch(),
              const SizedBox(height: 16),
              _buildDateTimeField(
                label: 'Sales Start Time',
                value: _salesStartTime,
                onSelect: (date) => setState(() => _salesStartTime = date),
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(
                label: 'Sales End Time',
                value: _salesEndTime,
                onSelect: (date) => setState(() => _salesEndTime = date),
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(
                label: 'Event Date',
                value: _eventDate,
                onSelect: (date) => setState(() => _eventDate = date),
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(
                label: 'Refund End Date (Optional)',
                value: _refundEndDate,
                onSelect: (date) => setState(() => _refundEndDate = date),
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildRefundPolicyField(),
              const SizedBox(height: 16),
              _buildRefundPercentageField(),
              const SizedBox(height: 24),
              _buildSubmitButton(createState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      controller: _nameController,
      hintText: 'Event Name',
      prefixIcon: Icons.event,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Event name is required';
        }
        return null;
      },
    );
  }

  Widget _buildIsSeatedSwitch() {
    return SwitchListTile(
      title: Text('Seated Event', style: AppTextStyles.bodyLarge),
      subtitle: Text(
        _isSeated ? 'Seats will be generated' : 'Standing / general admission',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
      ),
      value: _isSeated,
      onChanged: (value) => setState(() => _isSeated = value),
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onSelect,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: () => _pickDateTime(onSelect),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.hint,
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: Text(
          value != null
              ? _dateFormat.format(value)
              : (isOptional ? 'Select date & time' : 'Select date & time *'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: value != null ? null : AppColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRefundPolicyField() {
    return CustomTextField(
      controller: _refundPolicyController,
      hintText: 'Refund Policy (Optional)',
      prefixIcon: Icons.info_outline,
      maxLines: 2,
    );
  }

  Widget _buildRefundPercentageField() {
    return CustomTextField(
      controller: _refundPercentageController,
      hintText: 'Refund Percentage (Optional)',
      prefixIcon: Icons.percent,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildSubmitButton(CreateEventState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: state.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text('Create Event', style: AppTextStyles.button),
      ),
    );
  }

  Future<void> _pickDateTime(ValueChanged<DateTime> onSelect) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onSelect(dateTime);
      }
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_salesStartTime == null ||
        _salesEndTime == null ||
        _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required date fields',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_salesEndTime!.isBefore(_salesStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sales end time must be after sales start time',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_eventDate!.isBefore(_salesEndTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event date must be after sales end time',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_refundEndDate != null && _refundEndDate!.isBefore(_salesStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund end date must be after sales start time',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = CreateEventRequest(
      name: _nameController.text.trim(),
      isSeated: _isSeated,
      salesStartTime: _salesStartTime!,
      salesEndTime: _salesEndTime!,
      eventDate: _eventDate!,
      refundEndDate: _refundEndDate,
      refundPolicy: _refundPolicyController.text.trim().isNotEmpty
          ? _refundPolicyController.text.trim()
          : null,
      refundPercentage: _refundPercentageController.text.trim().isNotEmpty
          ? int.tryParse(_refundPercentageController.text.trim())
          : null,
    );

    ref.read(createEventProvider.notifier).createEvent(request);
  }
}
