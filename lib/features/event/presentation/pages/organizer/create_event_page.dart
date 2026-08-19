import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/core/widgets/custom_text_field.dart';
import 'package:team_five_fe/features/event/data/models/create_event_request.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/ticket_category/presentation/pages/organizer/ticket_category_page.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _refundPolicyController = TextEditingController();
  final _refundPercentageController = TextEditingController();

  bool _isSeated = false;
  DateTime? _salesStartTime;
  DateTime? _salesEndTime;
  DateTime? _eventDate;
  DateTime? _refundEndDate;
  File? _selectedImage;

  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _refundPolicyController.dispose();
    _refundPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createEventProvider);

    ref.listen<CreateEventState>(createEventProvider, (previous, next) {
      if (next.isSuccess && next.createdEvent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event created successfully!',
              style: AppTextStyles.snackbar,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        final event = next.createdEvent!;
        ref.read(createEventProvider.notifier).reset();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TicketCategoryPage(
              eventId: event.id,
              eventName: event.name,
              isSeated: event.isSeated,
              eventDate: event.eventDate,
            ),
          ),
        );
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: AppTextStyles.snackbar),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.white),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -15,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: 20,
                        child: Icon(
                          Icons.celebration_outlined,
                          size: 40,
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'New Event',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create Event',
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fill in the details to create your event',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Event Info Section
                  _buildSectionCard(
                    title: 'Event Info',
                    icon: Icons.info_outline,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 12),
                      _buildNameField(),
                      const SizedBox(height: 12),
                      _buildDescriptionField(),
                      const SizedBox(height: 12),
                      _buildIsSeatedSwitch(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Schedule Section
                  _buildSectionCard(
                    title: 'Schedule',
                    icon: Icons.schedule,
                    children: [
                      _buildDateTimeField(
                        label: 'Sales Start Time',
                        value: _salesStartTime,
                        onSelect: (date) =>
                            setState(() => _salesStartTime = date),
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeField(
                        label: 'Sales End Time',
                        value: _salesEndTime,
                        onSelect: (date) =>
                            setState(() => _salesEndTime = date),
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeField(
                        label: 'Event Date',
                        value: _eventDate,
                        onSelect: (date) => setState(() => _eventDate = date),
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeField(
                        label: 'Refund End Date',
                        value: _refundEndDate,
                        onSelect: (date) =>
                            setState(() => _refundEndDate = date),
                        isOptional: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Refund Settings Section
                  _buildSectionCard(
                    title: 'Refund Settings',
                    icon: Icons.replay,
                    children: [
                      _buildRefundPolicyField(),
                      const SizedBox(height: 12),
                      _buildRefundPercentageField(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  _buildSubmitButton(createState),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with gradient accent
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.pink.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
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

  Widget _buildDescriptionField() {
    return CustomTextField(
      controller: _descriptionController,
      hintText: 'Event Description',
      prefixIcon: Icons.description_outlined,
      maxLines: 5,
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: _selectedImage != null ? 200 : 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Event Photo',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select from gallery',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.topRight,
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildIsSeatedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isSeated
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSeated
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.greyLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSeated
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isSeated ? Icons.event_seat : Icons.stadium,
              size: 18,
              color: _isSeated ? AppColors.primary : AppColors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seated Event',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSeated
                      ? 'Seats will be generated'
                      : 'Standing / general admission',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isSeated,
            onChanged: (value) => setState(() => _isSeated = value),
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.greyLight,
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.hint,
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? _dateFormat.format(value)
                    : (isOptional
                          ? 'Select date & time'
                          : 'Select date & time *'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: value != null ? null : AppColors.grey,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundPolicyField() {
    return CustomTextField(
      controller: _refundPolicyController,
      hintText: 'Refund Policy',
      prefixIcon: Icons.info_outline,
      maxLines: 2,
    );
  }

  Widget _buildRefundPercentageField() {
    return CustomTextField(
      controller: _refundPercentageController,
      hintText: 'Refund Percentage',
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
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('Create Event', style: AppTextStyles.button),
                ],
              ),
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
          backgroundColor: AppColors.danger,
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
          backgroundColor: AppColors.danger,
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
          backgroundColor: AppColors.danger,
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
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_refundEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund end date is required',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Description is required',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_refundPolicyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund policy is required',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_refundPercentageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund percentage is required',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final refundPercentage = int.tryParse(_refundPercentageController.text.trim());
    if (refundPercentage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund percentage must be a valid number',
            style: AppTextStyles.snackbar,
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final request = CreateEventRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isSeated: _isSeated,
      salesStartTime: _salesStartTime!,
      salesEndTime: _salesEndTime!,
      eventDate: _eventDate!,
      refundEndDate: _refundEndDate!,
      refundPolicy: _refundPolicyController.text.trim(),
      refundPercentage: refundPercentage,
    );

    ref
        .read(createEventProvider.notifier)
        .createEvent(request, imageFile: _selectedImage);
  }
}
