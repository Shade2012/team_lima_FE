import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloce/features/auth/presentation/providers/auth_provider.dart';
import 'package:veloce/features/auth/presentation/pages/login_page.dart';
import 'package:veloce/features/event/presentation/pages/organizer/organizer_main_screen.dart';
import 'package:veloce/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:veloce/features/gate/presentation/pages/gate_operator/gate_operator_dashboard_page.dart';
import 'package:veloce/features/admin/presentation/pages/admin_main_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    final user = authState.currentUser;

    if (user?.role == 'ADMIN') {
      return const AdminMainScreen();
    }

    if (user?.role == 'ORGANIZER' || user?.role == 'EVENT_ORGANIZER') {
      return const OrganizerMainScreen();
    }

    if (user?.role == 'GATE_OPERATOR') {
      return const GateOperatorDashboardPage();
    }

    return const CustomerMainScreen();
  }
}
